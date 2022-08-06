# Kernel runtime

This directory contains all the architecture specific code needed to run the
kernel.

For an architecture A there is a type `A` exported from `arch.zig`. This type
has fields corresponding to features of the kernel which require architecture
specific support.

Features are exported through `krt.zig`. Requesting a non existent architecture
or an unsupported feature results in a compilation error.

## Features

\[Work in progress. Stable API to be derived later.\]

### runtime

Boots the kernel

Finds `pub fn kmain() !void` in the root file and calls it. Causes kernel panic
on error.

Defines `pub fn panic(_: []const u8, _: ?*StackTrace) noreturn`.


### terminal

Allows text to be rendered. No defined API yet.
