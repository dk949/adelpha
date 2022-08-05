const std = @import("std");
const utils = @import("utils.zig");
const Step = std.build.Step;
const Builder = std.build.Builder;
const ArrayList = std.ArrayList;
const fs = std.fs;

const FsStep = @This();

pub const base_id = .custom;

pub const FsAction = union(enum) {
    none: void,
    cp: struct {
        to: []const u8,
        from: []const u8,
    },
    mkdir: struct {
        path: []const u8,
        parents: bool = false,
    },
    rm: struct {
        path: []const u8,
        recursive: bool,
        force: bool,
    },
};

/// public
step: Step,
/// public
builder: *Builder,

/// private
action: FsAction,

pub fn create(builder: *Builder, name: []const u8, action: FsAction) *FsStep {
    const self = builder.allocator.create(FsStep) catch unreachable;
    self.* = FsStep{
        .builder = builder,
        .step = Step.init(base_id, name, builder.allocator, make),
        .action = action,
    };
    return self;
}

fn make(step: *Step) !void {
    const self = @fieldParentPtr(FsStep, "step", step);

    switch (self.action) {
        FsAction.cp => |cmd| {
            try fs.copyFileAbsolute(cmd.from, cmd.to, .{});
        },
        FsAction.mkdir => |cmd| {
            var dir = try fs.openDirAbsolute("/", .{});
            defer dir.close();
            try dir.makePath(cmd.path);
        },
        FsAction.rm => |cmd| {
            if (cmd.recursive)
                try fs.deleteTreeAbsolute(cmd.path)
            else
                try fs.deleteFileAbsolute(cmd.path);
        },
        FsAction.none => {
            std.log.warn("FsStep was used with a none action.", .{});
        },
    }

    self.step.done_flag = true;
}
