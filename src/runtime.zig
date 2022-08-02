const builtin = @import("std").builtin;
const terminal = @import("terminal.zig");

const MultiBoot = packed struct {
    magic: i32,
    flags: i32,
    checksum: i32,
};

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

export var multiboot align(4) linksection(".multiboot") = MultiBoot{
    .magic = MAGIC,
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_bytes_slice = stack_bytes[0..];

extern fn kmain() void;

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, _kmain, .{});

    while (true) {}
}

fn _kmain() void {
    terminal.initialize();
    kmain();
}

pub fn panic(msg: []const u8, error_return_trace: ?*builtin.StackTrace) noreturn {
    @setCold(true);
    terminal.write("KERNEL PANIC: ");
    terminal.write(msg);
    terminal.write("\n");

    if (error_return_trace) |stack| {
        for (stack.instruction_addresses) |address|
            terminal.writeNum(address);
        terminal.write("\n");
    } else terminal.write("no stack trace");
    while (true) {}
}
