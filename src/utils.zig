pub fn hexToStr(num: anytype) [@sizeOf(@TypeOf(num)) * 2]u8 {
    comptime if (!@import("std").meta.trait.isIntegral(@TypeOf(num)))
        @compileError("argument to hexToStr has to be an integer, not " ++ @typeName(@TypeOf(num)));

    var n = num;
    var ret: [@sizeOf(@TypeOf(num)) * 2]u8 = undefined;
    @memset(&ret, 0, ret.len);
    var i: usize = ret.len - @clz(@TypeOf(num), num) / 4;
    while (n != 0) : (n >>= 4) {
        ret[@intCast(usize, i - 1)] = '0' + (@truncate(u8, n) & 0x0f);
        i -= 1;
    }
    return ret;
}

// TODO: when There is some allocator interface
//fn split(allocator: Allocator, str: []const u8, sep: u8) !ArrayList([]const u8) {
//var out = ArrayList([]const u8).init(allocator);

//var start: usize = 0;
//var end: usize = 0;

//for (str) |ch| {
//end += 1;
//if (ch == sep) {
//try out.append(str[start .. end - 1]);
//start = end;
//}
//}

//return out;
//}

