comptime {
    _ = @import("krt").runtime;
}
const krt = @import("krt");
const terminal = krt.terminal;
const builtin = @import("builtin");
const cpu = builtin.cpu;

pub fn kmain() !void {
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
    terminal.write(@tagName(cpu.arch));
    terminal.write(" ");
    terminal.write(cpu.model.name);
    terminal.write(" cpu.\n");
    terminal.write("\n\n\nyay!!\n");
}
