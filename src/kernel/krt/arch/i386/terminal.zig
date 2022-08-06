const utils = @import("utils.zig");
const mem = @import("std").mem;

pub fn initialize() void {
    var y: usize = 0;
    while (y < VGA_HEIGHT) : (y += 1) {
        var x: usize = 0;
        while (x < VGA_WIDTH) : (x += 1) {
            putCharAt(' ', color, x, y);
        }
    }
}

pub fn setColor(new_color: u8) void {
    color = new_color;
}

pub fn write(data: []const u8) void {
    for (data) |c|
        putChar(c);
}

pub fn writeNum(num: usize) void {
    write(mem.sliceTo(&utils.hexToStr(num), 0));
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

fn vga_entry(uc: u8, cl: u8) u16 {
    var c: u16 = cl;

    return uc | (c << 8);
}

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;

var row: usize = 0;
var column: usize = 0;

var color = vga_entry_color(.VGA_COLOR_LIGHT_GREY, .VGA_COLOR_BLUE);

const buffer = @intToPtr([*]volatile u16, 0xB8000);

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
