const builtin = @import("std").builtin;
const meta = @import("std").meta;
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

export fn _start() callconv(.Naked) noreturn {
    @call(.{ .stack = stack_bytes_slice }, _kmain, .{});

    while (true) {}
}

fn _kmain() void {
    terminal.initialize();
    const root = @import("root");

    if (!@hasDecl(root, "kmain"))
        @compileError("Missing kmain in file " ++ @typeName(root) ++ ".zig");

    switch (@typeInfo(@TypeOf(root.kmain))) {
        else => @compileError("Expected kmain to be a function"),

        .Fn => |fn_| {
            if (fn_.args.len != 0) @compileError("Expected kmain to take no arguments");

            switch (@typeInfo(fn_.return_type.?)) {
                else => @compileError("Expected kmain to return !void"),

                .ErrorUnion => |errUnion| {
                    if (errUnion.payload != void) @compileError("Expected kmain to return !void");

                    return root.kmain() catch |err|
                        @panic("kmain exited with error: " ++ @errorName(err));
                },
            }
        },
    }

    @compileError("Internal error: did not call kmain");
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
