const std = @import("std");
const utils = @import("utils.zig");
const Step = std.build.Step;
const Builder = std.build.Builder;
const ArrayList = std.ArrayList;

const PathDependencyStep = @This();

pub const base_id = .custom;

/// public
step: Step,
/// public
builder: *Builder,

/// private
pathDeps: ArrayList([]const u8),

pub fn create(builder: *Builder, name: []const u8) *PathDependencyStep {
    const self = builder.allocator.create(PathDependencyStep) catch unreachable;
    self.* = PathDependencyStep{
        .builder = builder,
        .step = Step.init(base_id, name, builder.allocator, make),
        .pathDeps = ArrayList([]const u8).init(builder.allocator),
    };
    return self;
}

pub fn addDependency(self: *PathDependencyStep, name: []const u8) void {
    self.pathDeps.append(name) catch unreachable;
}

fn make(step: *Step) !void {
    const self = @fieldParentPtr(PathDependencyStep, "step", step);
    for (self.pathDeps.items) |dep| {
        if (!utils.exeInPath(dep)) {
            const stdout =
                std.io
                .getStdOut()
                .writer();
            stdout.print(
                \\
                \\################################################################################
                \\Error: could not find required executable `{s}`, make sure it is in $PATH"
                \\################################################################################
                \\
                \\
            , .{dep}) catch unreachable;
            return error.NoSuchExe;
        }
    }
    self.step.done_flag = true;
}
