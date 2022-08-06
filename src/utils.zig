pub const mem = @import("std").mem;

// TODO: make generic
pub fn hexToStr(num: usize) [@sizeOf(usize) * 2]u8 {
    comptime if (!@import("std").meta.trait.isIntegral(@TypeOf(num)))
        @compileError("argument to hexToStr has to be an integer, not " ++ @typeName(@TypeOf(num)));

    var ret: [@sizeOf(@TypeOf(num)) * 2]u8 = undefined;
    @memset(&ret, 0, ret.len);
    switch (num) {
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9 => |n| {
            ret[0] = '0' + @intCast(u8, n);
            return ret;
        },
        10, 11, 12, 13, 14, 15 => |n| {
            ret[0] = 'A' - 10 + @intCast(u8, n);
            return ret;
        },
        else => {},
    }
    var n = num;
    var i: usize = ret.len - @clz(@TypeOf(num), num) / 4;
    while (n != 0) : (n >>= 4) {
        ret[i - 1] = blk: {
            const d = (@truncate(u8, n) & 0x0f);
            break :blk if ((d >= 0) and (d <= 9)) '0' + d else 'A' - 10 + d;
        };
        i -= 1;
    }
    return ret;
}

test "hex to string" {
    const expect = @import("std").testing.expect;
    const testNum: usize = 0x21;
    try expect(mem.eql(u8, &hexToStr(testNum), "1"));
}

/// Remove the outer most layer of const from T if T is a pointer type.
/// Note: this does not make a const value modifiable.
/// *const T -> *T
///       *T -> *T
/// *const *const T -> **const T
pub fn removeConst(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Pointer => blk: {
            var cpy = @typeInfo(T);
            cpy.Pointer.is_const = false;
            break :blk @Type(cpy);
        },
        else => |t| @compileError("Cannot remove const from " ++ @typeName(@Type(t))),
    };
}
test "remove const" {
    const expect = @import("std").testing.expect;
    try expect(removeConst(*const i32) == *i32);
    try expect(removeConst([]const i32) == []i32);
    try expect(removeConst([*]const i32) == [*]i32);
    try expect(removeConst([:0]const i32) == [:0]i32);
    try expect(removeConst([*:0]const i32) == [*:0]i32);
    try expect(removeConst(*const *const i32) == **const i32);

    try expect(removeConst(*i32) == *i32);
    try expect(removeConst([]i32) == []i32);
    try expect(removeConst([*]i32) == [*]i32);
    try expect(removeConst([:0]i32) == [:0]i32);
    try expect(removeConst([*:0]i32) == [*:0]i32);
    try expect(removeConst(**const i32) == **const i32);
}

/// Add const to the outer most layer of T if T is a pointer type.
///       *T -> *const T
/// *const T -> *const T
/// **const T -> *const *const T
pub fn addConst(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .Pointer => blk: {
            var cpy = @typeInfo(T);
            cpy.Pointer.is_const = true;
            break :blk @Type(cpy);
        },
        else => |t| @compileError("Cannot add const to " ++ @typeName(@Type(t))),
    };
}

test "add const" {
    const expect = @import("std").testing.expect;
    try expect(addConst(*i32) == *const i32);
    try expect(addConst([]i32) == []const i32);
    try expect(addConst([*]i32) == [*]const i32);
    try expect(addConst([:0]i32) == [:0]const i32);
    try expect(addConst([*:0]i32) == [*:0]const i32);
    try expect(addConst(**const i32) == *const *const i32);

    try expect(addConst(*const i32) == *const i32);
    try expect(addConst([]const i32) == []const i32);
    try expect(addConst([*]const i32) == [*]const i32);
    try expect(addConst([:0]const i32) == [:0]const i32);
    try expect(addConst([*:0]const i32) == [*:0]const i32);
    try expect(addConst(*const *const i32) == *const *const i32);
}
