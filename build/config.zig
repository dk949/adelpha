const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Target = std.Target;

pub const OS_NAME = "adelpha";

pub const target = CrossTarget{
    .cpu_arch = Target.Cpu.Arch.i386,
    .cpu_model = .baseline,
    .os_tag = Target.Os.Tag.freestanding,
};

pub const supported_host_os: []std.Target.Os.Tag = .{std.Target.Os.Tag.linux};

pub fn checkOs() void {
    const os: std.Target.Os = @import("builtin").os;
    comptime if (!(os.tag.isBSD() or os.tag == .linux))
        @compileError("\n\n" ++ @tagName(os.tag) ++
            \\ is not a supported host OS.
            \\You could try to rebuild without this check, but chances of success are pretty much 0.
            \\
            \\Supported platforms are any form of Linux or BSD (including MacOS).
            \\
            \\
        );
}

// pub const stdlib = "/usr/lib/zig/lib";
pub const stdlib: ?[]const u8 = null;
