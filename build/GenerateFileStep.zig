const std = @import("std");
const utils = @import("utils.zig");
const Step = std.build.Step;
const Builder = std.build.Builder;
const ArrayList = std.ArrayList;
const fs = std.fs;

const GenerateFileStep = @This();

pub const base_id = .custom;

/// public
step: Step,
/// public
builder: *Builder,

/// private
fileName: []const u8,
/// private
fileContents: []const u8,

pub fn create(builder: *Builder, name: []const u8, fileName: []const u8, fileContents: []const u8) *GenerateFileStep {
    const self = builder.allocator.create(GenerateFileStep) catch unreachable;
    self.* = GenerateFileStep{
        .builder = builder,
        .step = Step.init(base_id, name, builder.allocator, make),
        .fileName = fileName,
        .fileContents = fileContents,
    };
    return self;
}

fn make(step: *Step) !void {
    const self = @fieldParentPtr(GenerateFileStep, "step", step);

    var fp = try fs.createFileAbsolute(self.fileName, .{});
    defer fp.close();

    try fp.writeAll(self.fileContents);

    self.step.done_flag = true;
}
