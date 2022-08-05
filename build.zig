const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Mode = std.builtin.Mode;
const Target = std.Target;
const Builder = std.build.Builder;
const FileSource = std.build.FileSource;
const LibExeObjStep = std.build.LibExeObjStep;
const Step = std.build.Step;
const RunStep = std.build.RunStep;
const PathDependencyStep = @import("build/PathDependencyStep.zig");
const FsStep = @import("build/FsStep.zig");
const GenerateFileStep = @import("build/GenerateFileStep.zig");

const OS_NAME = "adelpha";

const ArtifactTag = struct { artifact: *LibExeObjStep };

const Build = struct {
    const Self = Build;

    builder: *Builder,
    mode: Mode,
    target: CrossTarget,
    arch_str: []const u8 = undefined,
    qemu: []const u8 = undefined,
    default_ld: ?FileSource = null,

    fn setDefaultLdOr(self: *Self, leo: *LibExeObjStep, alt: ?FileSource) void {
        if (self.default_ld orelse alt) |ld|
            leo.setLinkerScriptPath(ld);
    }

    fn addObject(self: *Self, name: []const u8, source: []const u8) *LibExeObjStep {
        var obj = self.builder.addObject(name, source);
        obj.setBuildMode(self.mode);
        obj.setTarget(self.target);
        self.setDefaultLdOr(obj, null);
        return obj;
    }

    fn addExecutable(self: *Self, name: []const u8, source: []const u8) *LibExeObjStep {
        var exe = self.builder.addExecutable(name, source);
        exe.setBuildMode(self.mode);
        exe.setTarget(self.target);
        self.setDefaultLdOr(exe, null);
        return exe;
    }

    fn addStep(self: *Self, name: []const u8, description: []const u8) *Step {
        return self.builder.step(name, description);
    }

    fn createPathDependencyStep(self: *Self, name: []const u8, deps: ?[]const []const u8) *PathDependencyStep {
        return PathDependencyStep.create(self.builder, name, deps);
    }

    fn createRunStep(self: *Self, name: []const u8) *RunStep {
        const run_step = RunStep.create(self.builder, name);
        return run_step;
    }

    fn createFsStep(self: *Self, name: []const u8, action: FsStep.FsAction) *FsStep {
        return FsStep.create(self.builder, name, action);
    }

    fn createGenerateFileStep(self: *Self, name: []const u8, file_name: []const u8, file_contents: []const u8) *GenerateFileStep {
        return GenerateFileStep.create(self.builder, name, file_name, file_contents);
    }

    fn joinPath(self: *Self, paths: []const []const u8) []const u8 {
        return std.fs.path.join(self.builder.allocator, paths) catch unreachable;
    }

    pub fn create(
        b: *Builder,
        mode: Mode,
        comptime target: CrossTarget,
        comptime default_ld: ?[]const u8,
    ) Self {
        var self = Self{
            .builder = b,
            .mode = mode,
            .target = target,
            .default_ld = if (default_ld) |ld| FileSource{ .path = ld } else null,
        };
        const arch_str = comptime std.meta.tagName(target.cpu_arch.?);
        self.arch_str = arch_str;
        self.qemu = "qemu-system-" ++ arch_str;
        return self;
    }

    pub fn build(self: *Self) void {
        const rt = self.addObject("runtime", "src/runtime.zig");
        const exe = self.addExecutable("kernel", "src/kernel.zig");

        exe.addObject(rt);
        exe.install();

        const check_qemu = self.createPathDependencyStep("check qemu", &.{self.qemu});

        const run_step = self.createRunStep("run qemu");
        run_step.addArgs(&.{ self.qemu, "-kernel" });
        run_step.addArtifactArg(exe);
        run_step.step.dependOn(&exe.install_step.?.step);
        run_step.step.dependOn(&check_qemu.step);

        const run = self.addStep("run", "Run the kernel in qemu");
        run.dependOn(&run_step.step);

        const check_iso_prereqs = self.createPathDependencyStep(
            "check iso creation prerequisites",
            &.{ "xorriso", "mformat", "grub-mkrescue" },
        );
        _ = check_iso_prereqs;

        const isodir_path = self.joinPath(&.{ self.builder.install_prefix, "isodir" });
        const isodir_boot_path = self.joinPath(&.{ isodir_path, "boot" });
        const isodir_grub_path = self.joinPath(&.{ isodir_boot_path, "grub" });

        const mkdir_isodir = self.createFsStep("mkdir isodir", .{
            .mkdir = .{
                .path = isodir_grub_path,
                .parents = true,
            },
        });

        const cp_kernel = self.createFsStep("cp kernel", .{
            .cp = .{
                .to = self.joinPath(&.{ isodir_boot_path, OS_NAME ++ ".bin" }),
                .from = self.joinPath(&.{ self.builder.install_prefix, "bin", "kernel" }),
            },
        });
        cp_kernel.step.dependOn(&exe.install_step.?.step);
        cp_kernel.step.dependOn(&mkdir_isodir.step);

        const generate_grub_cfg = self.createGenerateFileStep(
            "generate grub.cfg",
            self.joinPath(&.{ isodir_grub_path, "grub.cfg" }),
            \\menuentry
            ++ " " ++ OS_NAME ++ "{" ++
                \\
                \\    multiboot /boot/
            ++ OS_NAME ++ ".bin" ++
                \\
                \\}
            ,
        );
        generate_grub_cfg.step.dependOn(&mkdir_isodir.step);

        const iso_location = self.joinPath(&.{ self.builder.install_prefix, "bin", OS_NAME ++ ".iso" });

        const mkiso_step = self.createRunStep("make iso");
        mkiso_step.addArgs(&.{ "grub-mkrescue", "-o", iso_location, isodir_path });
        mkiso_step.step.dependOn(&check_iso_prereqs.step);
        mkiso_step.step.dependOn(&generate_grub_cfg.step);
        mkiso_step.step.dependOn(&cp_kernel.step);

        const mkiso = self.addStep("mkiso", "Create a bootable ISO image");
        mkiso.dependOn(&mkiso_step.step);

        const runiso_step = self.createRunStep("run iso");
        runiso_step.addArgs(&.{ self.qemu, "-cdrom", iso_location });
        runiso_step.step.dependOn(&mkiso_step.step);
        runiso_step.step.dependOn(&check_qemu.step);

        const runiso = self.addStep("runiso", "Run the generated iso image in qemu");
        runiso.dependOn(&runiso_step.step);
    }
};

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.i386,
        .cpu_model = .{ .baseline = .{} },
        .os_tag = Target.Os.Tag.freestanding,
    };

    var buildManager = Build.create(b, mode, target, "src/linker.ld");
    buildManager.build();
}
