const terminal = @import("terminal.zig");

export fn kmain() void {
    terminal.initialize();
    terminal.write("Hello, Kernel World from Zig 0.10.0-dev!\n");
}
