const builtin = @import("std").builtin;
const meta = @import("std").meta;
const mem = @import("std").mem;
const heap = @import("std").heap;
const terminal = @import("terminal.zig");
const serial = @import("serial.zig");

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

export var stack_bytes: [16 * 1024]u8 align(16) linksection(".stack_bytes") = undefined;
pub const stack_bytes_slice = stack_bytes[0..];

export fn _start() callconv(.Naked) void {
    @call(.{ .stack = stack_bytes_slice }, _kmain, .{});

    //while (true) {}
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

                    terminal.write("Calling main\n");
                    return root.kmain() catch {
                        @panic("kmain exited with error");
                    };
                },
            }
        },
    }

    @compileError("Internal error: did not call kmain");
}

pub fn panic(msg: []const u8, error_return_trace: ?*@import("std").builtin.StackTrace, _: ?usize) noreturn {
    @setCold(true);
    terminal.write("KERNEL PANIC: ");
    terminal.write(msg);
    terminal.write("\n");

    if (error_return_trace) |stack| {
        terminal.write("Stack trace: \n");
        var zeroCount: usize = 0;
        for (stack.instruction_addresses) |address| {
            if (address == 0) {
                zeroCount += 1;
            } else {
                terminal.write("\t0x");
                terminal.writeNum(address);
                terminal.write("\n");
            }
        }
        terminal.write("\t0x0 x ");
        terminal.writeNum(zeroCount);
        terminal.write("\n");
    } else {
        terminal.write("no stack trace");
    }
    while (true) {}
}
