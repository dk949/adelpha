const builtin = @import("std").builtin;
const lib = @import("lib.zig");

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
    @call(.{ .stack = stack_bytes_slice }, kmain, .{});

    while (true) {}
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

fn kmain() void {
    terminal.initialize();
    terminal.write("Hello, Kernel World from Zig 0.10.0-dev!\n");
    //terminal.write("a\taa\taaa\taaaa\ta\n");
    //terminal.write("aaaa\taaa\taa\ta\ta\n");
}

// Hardware text mode color constants
const VgaColor = enum(u8) {
    VGA_COLOR_BLACK = 0,
    VGA_COLOR_BLUE = 1,
    VGA_COLOR_GREEN = 2,
    VGA_COLOR_CYAN = 3,
    VGA_COLOR_RED = 4,
    VGA_COLOR_MAGENTA = 5,
    VGA_COLOR_BROWN = 6,
    VGA_COLOR_LIGHT_GREY = 7,
    VGA_COLOR_DARK_GREY = 8,
    VGA_COLOR_LIGHT_BLUE = 9,
    VGA_COLOR_LIGHT_GREEN = 10,
    VGA_COLOR_LIGHT_CYAN = 11,
    VGA_COLOR_LIGHT_RED = 12,
    VGA_COLOR_LIGHT_MAGENTA = 13,
    VGA_COLOR_LIGHT_BROWN = 14,
    VGA_COLOR_WHITE = 15,
};

fn vga_entry_color(fg: VgaColor, bg: VgaColor) u8 {
    return @enumToInt(fg) | (@enumToInt(bg) << 4);
}

fn vga_entry(uc: u8, color: u8) u16 {
    var c: u16 = color;

    return uc | (c << 8);
}

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

const terminal = struct {
    var row: usize = 0;
    var column: usize = 0;

    var color = vga_entry_color(.VGA_COLOR_LIGHT_GREY, .VGA_COLOR_BLUE);

    const buffer = @intToPtr([*]volatile u16, 0xB8000);

    fn initialize() void {
        var y: usize = 0;
        while (y < VGA_HEIGHT) : (y += 1) {
            var x: usize = 0;
            while (x < VGA_WIDTH) : (x += 1) {
                putCharAt(' ', color, x, y);
            }
        }
    }

    fn setColor(new_color: u8) void {
        color = new_color;
    }

    fn putCharAt(c: u8, new_color: u8, x: usize, y: usize) void {
        const index = y * VGA_WIDTH + x;
        buffer[index] = vga_entry(c, new_color);
    }

    fn putChar(c: u8) void {
        switch (c) {
            '\n' => {
                row = (row + 1) % VGA_HEIGHT;
                column = 0;
            },
            '\t' => {
                column = column + (4 - (column % 4));
                if (column >= VGA_WIDTH) {
                    column = 0;
                    row = (row + 1) % VGA_HEIGHT;
                }
            },
            else => {
                putCharAt(c, color, column, row);
                column += 1;
                if (column >= VGA_WIDTH) {
                    column = 0;
                    row = (row + 1) % VGA_HEIGHT;
                }
            },
        }
    }

    fn write(data: []const u8) void {
        for (data) |c|
            putChar(c);
    }

    fn writeNum(num: usize) void {
        write(&lib.hexToStr(num));
    }
};
