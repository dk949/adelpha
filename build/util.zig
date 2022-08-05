const std = @import("std");
const Target = std.Target;

pub fn isPosix(tag: Target.Os.Tag) bool {
    return Target.Os.Tag.isBSD(tag) or switch (tag) {
        // yes
        .aix,
        .cloudabi,
        .linux,
        .minix,
        .solaris,

        // sort of
        .ananas,
        .haiku,
        .hurd,
        .plan9,
        .rtems,
        => true,

        // no
        .contiki,
        .fuchsia,
        .windows,
        .zos,

        // No idea, probably no
        .hermit,
        .lv2,
        .other,

        // Not an OS
        .amdhsa,
        .amdpal,
        .cuda,
        .elfiamcu,
        .emscripten,
        .freestanding,
        .glsl450,
        .mesa3d,
        .nacl,
        .nvcl,
        .opencl,
        .ps4,
        .uefi,
        .vulkan,
        .wasi,
        => false,
        .ios, .macos, .watchos, .tvos, .freebsd, .dragonfly, .kfreebsd, .netbsd, .openbsd => @panic("Unreachable"),
    };
}
