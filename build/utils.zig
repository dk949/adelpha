const std = @import("std");

pub fn exeInPath(exe: []const u8) bool {
    const path = std.os.getenv("PATH").?;

    var start: usize = 0;
    var end: usize = 0;

    outer: for (path) |ch| {
        end += 1;
        if (ch == ':') {
            var d = std.fs.openDirAbsolute(path[start .. end - 1], .{ .iterate = true }) catch continue :outer;
            defer d.close();
            var iter = d.iterate();
            var pathDir = iter.next() catch continue :outer;
            while (pathDir != null) : (pathDir = iter.next() catch continue :outer)
                if (std.mem.eql(u8, pathDir.?.name, exe))
                    return true;
            start = end;
        }
    }
    return false;
}
