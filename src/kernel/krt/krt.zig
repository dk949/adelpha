pub const runtime = load("runtime");
pub const terminal = load("terminal");
pub const serial = load("serial");

////////////////////////////////////////

const cpu_arch = @tagName(@import("builtin").cpu.arch);
const arch = @import("arch/arch.zig");

pub fn load(comptime name: []const u8) type {
    return // if arch exists and has requested feature, it is exported
    if (!@hasDecl(arch, cpu_arch))
        @compileError(cpu_arch ++ " is not a supported architecture")
    else if (!@hasDecl(@field(arch, cpu_arch), name))
        @compileError(name ++ " is not supported on " ++ cpu_arch ++ " architecture")
    else
        @field(@field(arch, cpu_arch), name);
}
