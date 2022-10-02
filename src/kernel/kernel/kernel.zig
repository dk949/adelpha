comptime {
    _ = @import("krt").runtime;
}

const krt = @import("krt");
pub const panic = krt.runtime.panic;

const terminal = krt.terminal;
const builtin = @import("builtin");
const fmt = @import("std").fmt;
const debug = @import("std").debug;
const cpu = builtin.cpu;

pub fn kmain() !void {
    //const ver = builtin.zig_version;
    //terminal.write("Zig ");
    //terminal.writeNum(ver.major);
    //terminal.write(".");
    //terminal.writeNum(ver.minor);
    //terminal.write(".");
    //terminal.writeNum(ver.patch);
    //if (ver.pre) |pre| {
    //terminal.write("-");
    //terminal.write(pre);
    //}
    //if (ver.build) |build| {
    //terminal.write("+");
    //terminal.write(build);
    //}
    //terminal.write(" running on an ");
    //terminal.write(@tagName(cpu.arch));
    //terminal.write(" ");
    //terminal.write(cpu.model.name);
    //terminal.write(" cpu.\n");
    //terminal.write("\n\n\nyay!!\n");
    //const stack = krt.runtime.stack_bytes_slice;
    const log = krt.serial.SerialIO.getGlobal(null) catch unreachable;
    const writer = log.writer();
    _ = try writer.write("helllo\n");

    //log.write_("hello");
    //for (stack) |byte| {
    //log.write_(&.{byte});
    //log.write_("\n");
    //}
}
