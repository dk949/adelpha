extern fn _in8(port: c_ushort) u8;
extern fn _in16(port: c_ushort) c_ushort;
extern fn _in32(port: c_ushort) c_uint;
extern fn _out8(port: c_ushort, value: u8) void;
extern fn _out16(port: c_ushort, value: c_ushort) void;
extern fn _out32(port: c_ushort, value: c_uint) void;

inline fn delay(microseconds: usize) void {
    var i: usize = 0;
    while (i < microseconds) : (i += 1) return _in8(0x80);
}

pub const SerialIO = struct {
    pub const SerialError = error{
        FAULTY_SERIAL,
        COULD_NOT_WRITE,
        COULD_NOT_READ,
        MISMATCHED_GLOBAL_PORT,
    };
    const Self = @This();
    pub const BOCHS_DEBUG_PORT: u16 = 0xE9;
    pub const COM1 = 0x3f8;
    pub var global: ?SerialIO = null;

    address: u16,

    pub fn init(port: u16) !SerialIO {
        _out8(port + 1, 0x00); // Disable all interrupts
        _out8(port + 3, 0x80); // Enable DLAB (set baud rate divisor)
        _out8(port + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
        _out8(port + 1, 0x00); //                  (hi byte)
        _out8(port + 3, 0x03); // 8 bits, no parity, one stop bit
        _out8(port + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
        _out8(port + 4, 0x0B); // IRQs enabled, RTS/DSR set
        _out8(port + 4, 0x1E); // Set in loopback mode, test the serial chip
        _out8(port + 0, 0xAE); // Test serial chip (send byte 0xAE and check if serial returns same byte)
        // Check if serial is faulty (i.e: not same byte as sent)
        if (_in8(port + 0) != 0xAE) {
            return SerialError.FAULTY_SERIAL;
        }

        // If serial is not faulty set it in normal operation mode
        // (not-loopback with IRQs enabled and OUT#1 and OUT#2 bits enabled)
        _out8(port + 4, 0x0F);
        return SerialIO{ .address = port };
    }

    pub fn getGlobal(port: ?u16) SerialError!SerialIO {
        return //
        if (global) |g|
            if (port) |p|
                if (g.address == p)
                    SerialError.MISMATCHED_GLOBAL_PORT
                else
                    g
            else
                g
        else
            init(port orelse COM1);
    }

    fn received(self: SerialIO) bool {
        return _in8(self.address + 5) & 1 == 0;
    }

    pub fn getChar(self: SerialIO) u8 {
        while (self.received()) {}
        return _in8(self.address);
    }
    fn is_transmit_empty(self: SerialIO) bool {
        return _in8(self.address + 5) & 0x20 == 0;
    }

    pub fn putChar(self: SerialIO, a: u8) void {
        while (self.is_transmit_empty()) {}
        _out8(self.address, a);
    }

    pub fn write(self: SerialIO, bytes: []const u8) SerialError!usize {
        var i: usize = 0;
        for (bytes) |byte| {
            i += 1;
            self.putChar(byte);
        }
        return i;
    }

    pub fn write_(self: SerialIO, bytes: []const u8) void {
        _ = self.write(bytes) catch unreachable;
    }

    const io = @import("std").io;
    pub const Writer = io.Writer(SerialIO, SerialError, write);

    // TODO: number formatter does not work :(
    pub fn writer(self: SerialIO) Writer {
        return Writer{ .context = self };
    }
};
