const terminal = @import("terminal.zig");
const builtin = @import("builtin");
const cpu = builtin.cpu;
const utils = @import("utils.zig");

export fn kmain() void {
    const ver = builtin.zig_version;
    terminal.write("Zig ");
    terminal.writeNum(ver.major);
    terminal.write(".");
    terminal.writeNum(ver.minor);
    terminal.write(".");
    terminal.writeNum(ver.patch);
    if (ver.pre) |pre| {
        terminal.write("-");
        terminal.write(pre);
    }
    if (ver.build) |build| {
        terminal.write("+");
        terminal.write(build);
    }
    terminal.write(" running on an ");
    terminal.write(utils.enumToStr(cpu.arch));
    terminal.write(" ");
    terminal.write(cpu.model.name);
    terminal.write(" cpu.\n");
    terminal.write("\n\n\nyay!!\n");
}
