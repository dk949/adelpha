const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;
const FileSource = std.build.FileSource;
const Alloc = std.mem.Allocator;
const ArrayList = std.ArrayList;
const utils = @import("build/utils.zig");
const PathDependencyStep = @import("build/PathDependencyStep.zig");
const FsStep = @import("build/FsStep.zig");
const GenerateFileStep = @import("build/GenerateFileStep.zig");
const InstallDir = std.build.InstallDir;
const assert = std.debug.assert;
const path = std.fs.path;
const fs = std.fs;

const KERNEL_NAME = "zkernel";

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const target = CrossTarget{
        .cpu_arch = Target.Cpu.Arch.i386,
        .os_tag = Target.Os.Tag.freestanding,
    };

    const exe = b.addExecutable(KERNEL_NAME, "src/" ++ KERNEL_NAME ++ ".zig");
    exe.setBuildMode(mode);
    exe.setTarget(target);
    exe.setLinkerScriptPath(FileSource{ .path = "src/linker.ld" });
    exe.install();

    // Select correct qemu executable corresponding to the target CPU architecture
    const qemu = "qemu-system-" ++ @typeInfo(Target.Cpu.Arch).Enum.fields[@enumToInt(target.cpu_arch.?)].name;

    const check_qemu = PathDependencyStep.create(b, "check qemu");
    check_qemu.addDependency(qemu);

    const run_step = std.build.RunStep.create(b, "run quemu");
    run_step.addArg(qemu);
    run_step.addArg("-kernel");
    run_step.addArtifactArg(exe);
    run_step.step.dependOn(&exe.install_step.?.step);
    run_step.step.dependOn(&check_qemu.step);

    const run = b.step("run", "Run the kernel in qemu");
    run.dependOn(&run_step.step);

    const check_iso_prereqs = PathDependencyStep.create(b, "check iso creation prerequisites");
    check_iso_prereqs.addDependency("xorriso");
    check_iso_prereqs.addDependency("mformat");
    check_iso_prereqs.addDependency("grub-mkrescue");

    assert(b.install_prefix.len > 0);
    const isodir_path = path.join(b.allocator, &.{ b.install_prefix, "isodir" }) catch unreachable;
    const isodir_boot_path = path.join(b.allocator, &.{ isodir_path, "boot" }) catch unreachable;
    const isodir_grub_path = path.join(b.allocator, &.{ isodir_boot_path, "grub" }) catch unreachable;

    const mkdir_isodir = FsStep.create(b, "mkdir isodir", .{
        .mkdir = .{
            .path = isodir_grub_path,
            .parents = true,
        },
    });

    const cp_kernel = FsStep.create(b, "cp kernel", .{
        .cp = .{
            .to = path.join(b.allocator, &.{ isodir_boot_path, KERNEL_NAME ++ ".bin" }) catch unreachable,
            .from = path.join(b.allocator, &.{ b.install_prefix, "bin", KERNEL_NAME }) catch unreachable,
        },
    });
    cp_kernel.step.dependOn(&exe.install_step.?.step);
    cp_kernel.step.dependOn(&mkdir_isodir.step);

    var generate_grub_cfg = GenerateFileStep.create(
        b,
        "generate grub.cfg",
        path.join(b.allocator, &.{ isodir_grub_path, "grub.cfg" }) catch unreachable,
        \\menuentry
        ++ " " ++ KERNEL_NAME ++ "{" ++
            \\
            \\    multiboot /boot/
        ++ KERNEL_NAME ++ ".bin" ++
            \\
            \\}
        ,
    );
    generate_grub_cfg.step.dependOn(&mkdir_isodir.step);

    const iso_location = path.join(b.allocator, &.{ b.install_prefix, "bin", KERNEL_NAME ++ ".iso" }) catch unreachable;
    const mkiso_step = std.build.RunStep.create(b, "make iso");
    mkiso_step.addArgs(&.{ "grub-mkrescue", "-o", iso_location, isodir_path });
    mkiso_step.step.dependOn(&check_iso_prereqs.step);
    mkiso_step.step.dependOn(&generate_grub_cfg.step);
    mkiso_step.step.dependOn(&cp_kernel.step);

    const mkiso = b.step("mkiso", "Create a bootable ISO image");
    mkiso.dependOn(&mkiso_step.step);

    const runiso_step = std.build.RunStep.create(b, "run iso");
    runiso_step.addArg(qemu);
    runiso_step.addArgs(&.{ "-cdrom", iso_location });
    runiso_step.step.dependOn(&mkiso_step.step);
    runiso_step.step.dependOn(&check_qemu.step);

    const runiso = b.step("runiso", "Run the generated iso image in qemu");
    runiso.dependOn(&runiso_step.step);

    // TODO: add clean target
}
