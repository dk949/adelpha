//fn testMemEql(lhs: anytype, rhs: anytype) !void {
//expect(meta.Elem(@TypeOf(lhs)) == meta.Elem(@TypeOf(rhs))) catch |err| {
//print("Malformed test", .{});
//return err;
//};
//expect(mem.eql(meta.Elem(@TypeOf(lhs)), lhs, rhs)) catch |err| {
//switch (err) {
//error.TestUnexpectedResult => print("Test failed:\n\t{any} != {any}\n", .{ lhs, rhs }),
//else => {},
//}
//return err;
//};
//print("Test passed:\n\t{any} == {any}\n", .{ lhs, rhs });
//}

