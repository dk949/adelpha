const std = @import("std");
const config = @import("build/config.zig");
const Mode = std.builtin.Mode;
const Builder = std.build.Builder;
const FileSource = std.build.FileSource;
const LibExeObjStep = std.build.LibExeObjStep;
const Step = std.build.Step;
const RunStep = std.build.RunStep;
const PathDependencyStep = @import("build/PathDependencyStep.zig");
const FsStep = @import("build/FsStep.zig");
const GenerateFileStep = @import("build/GenerateFileStep.zig");

const ArtifactTag = struct { artifact: *LibExeObjStep };

var builder: *Builder = undefined;
var mode: Mode = undefined;
const arch_str = std.meta.tagName(config.target.cpu_arch.?);
const qemu = "qemu-system-" ++ arch_str;
var default_ld: FileSource = undefined;

fn setDefaultLdOr(leo: *LibExeObjStep, alt: ?FileSource) void {
    leo.setLinkerScriptPath(alt orelse default_ld);
}

fn addObject(name: []const u8, source: []const u8) *LibExeObjStep {
    var obj = builder.addObject(name, source);
    obj.setBuildMode(mode);
    obj.setTarget(config.target);
    setDefaultLdOr(obj, null);
    return obj;
}

fn addExecutable(name: []const u8, source: []const u8) *LibExeObjStep {
    var exe = builder.addExecutable(name, source);
    exe.setBuildMode(mode);
    exe.setTarget(config.target);
    setDefaultLdOr(exe, null);
    return exe;
}

fn addStep(name: []const u8, description: []const u8) *Step {
    return builder.step(name, description);
}

fn createPathDependencyStep(name: []const u8, deps: ?[]const []const u8) *PathDependencyStep {
    return PathDependencyStep.create(builder, name, deps);
}

fn createRunStep(name: []const u8) *RunStep {
    const run_step = RunStep.create(builder, name);
    return run_step;
}

fn createFsStep(name: []const u8, action: FsStep.FsAction) *FsStep {
    return FsStep.create(builder, name, action);
}

fn createGenerateFileStep(name: []const u8, file_name: []const u8, file_contents: []const u8) *GenerateFileStep {
    return GenerateFileStep.create(builder, name, file_name, file_contents);
}

fn joinPath(paths: []const []const u8) []const u8 {
    return std.fs.path.join(builder.allocator, paths) catch unreachable;
}

fn fromRelativePath(path: []const u8) []const u8 {
    return std.fs.cwd().realpathAlloc(builder.allocator, path) catch unreachable;
}

pub fn build(b: *std.build.Builder) void {
    config.checkOs();

    builder = b;
    mode = b.standardReleaseOptions();
    default_ld = FileSource{ .path = "src/linker.ld" };

    const rt = addObject("runtime", "src/runtime.zig");

    const exe = addExecutable("kernel", "src/kernel.zig");
    exe.addObject(rt);
    exe.install();

    const check_qemu = createPathDependencyStep("check qemu", &.{qemu});

    const run_step = createRunStep("run qemu");
    run_step.addArgs(&.{ qemu, "-kernel" });
    run_step.addArtifactArg(exe);
    run_step.step.dependOn(&exe.install_step.?.step);
    run_step.step.dependOn(&check_qemu.step);

    const run = addStep("run", "Run the kernel in qemu");
    run.dependOn(&run_step.step);

    const check_iso_prereqs = createPathDependencyStep(
        "check iso creation prerequisites",
        &.{ "xorriso", "mformat", "grub-mkrescue" },
    );
    _ = check_iso_prereqs;

    const isodir_path = joinPath(&.{ b.install_prefix, "isodir" });
    const isodir_boot_path = joinPath(&.{ isodir_path, "boot" });
    const isodir_grub_path = joinPath(&.{ isodir_boot_path, "grub" });

    const mkdir_isodir = createFsStep("mkdir isodir", .{
        .mkdir = .{
            .path = isodir_grub_path,
            .parents = true,
        },
    });

    const cp_kernel = createFsStep("cp kernel", .{
        .cp = .{
            .to = joinPath(&.{ isodir_boot_path, config.OS_NAME ++ ".bin" }),
            .from = joinPath(&.{ b.install_prefix, "bin", "kernel" }),
        },
    });
    cp_kernel.step.dependOn(&exe.install_step.?.step);
    cp_kernel.step.dependOn(&mkdir_isodir.step);

    const generate_grub_cfg = createGenerateFileStep(
        "generate grub.cfg",
        joinPath(&.{ isodir_grub_path, "grub.cfg" }),
        \\menuentry
        ++ " " ++ config.OS_NAME ++ "{" ++
            \\
            \\    multiboot /boot/
        ++ config.OS_NAME ++ ".bin" ++
            \\
            \\}
        ,
    );
    generate_grub_cfg.step.dependOn(&mkdir_isodir.step);

    const iso_location = joinPath(&.{ b.install_prefix, "bin", config.OS_NAME ++ ".iso" });

    const mkiso_step = createRunStep("make iso");
    mkiso_step.addArgs(&.{ "grub-mkrescue", "-o", iso_location, isodir_path });
    mkiso_step.step.dependOn(&check_iso_prereqs.step);
    mkiso_step.step.dependOn(&generate_grub_cfg.step);
    mkiso_step.step.dependOn(&cp_kernel.step);

    const mkiso = addStep("mkiso", "Create a bootable ISO image");
    mkiso.dependOn(&mkiso_step.step);

    const runiso_step = createRunStep("run iso");
    runiso_step.addArgs(&.{ qemu, "-cdrom", iso_location });
    runiso_step.step.dependOn(&mkiso_step.step);
    runiso_step.step.dependOn(&check_qemu.step);

    const runiso = addStep("runiso", "Run the generated iso image in qemu");
    runiso.dependOn(&runiso_step.step);

    const remove_cache = createFsStep("rm cache", .{
        .rm = .{
            .path = fromRelativePath(b.cache_root),
            .force = true,
            .recursive = true,
        },
    });

    const remove_bin = createFsStep("rm bin", .{
        .rm = .{
            .path = b.install_prefix,
            .force = true,
            .recursive = true,
        },
    });

    const clean = addStep("clean", "Remove artifacts");
    clean.dependOn(&remove_bin.step);

    const clean_all = addStep("cleanall", "Remove artifacts and cache");
    clean_all.dependOn(&remove_cache.step);
    clean_all.dependOn(clean);
}
