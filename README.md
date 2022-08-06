# Adelpha

Status: vapourware

Adelpha is a bare-bones exo-kernel with a small operating system on top of it.

Currently there are no particular goals, just get something working :)

## Build and run

Note: Only tested on Linux (kernel: 5.18.16-arch1-1). Will most likely work on
other distributions. Has a chance of working on BSD/OSX. Will most likely not
work on Windows.

### Build

#### Requires

* [zig](https://ziglang.org/) compiler v0.10 (tested with
  0.10.0-dev.2977+7d2e14267)

``` sh
zig build
```

### Run

#### Requires

* [zig](https://ziglang.org/) compiler v0.10 (tested with
  0.10.0-dev.2977+7d2e14267)
* [qemu-system-i386](https://www.qemu.org/) (tested with 7.0.0)

``` sh
zig build run
```

### Make bootable ISO

#### Requires

* [zig](https://ziglang.org/) compiler v0.10 (tested with
  0.10.0-dev.2977+7d2e14267)
* [xorriso](https://www.gnu.org/software/xorriso/) (tested with 1.5.4)
* [mformat](https://www.gnu.org/software/mtools/manual/html_node/mformat.html)
  (tested with 4.0.40)
* [grub-mkrescue](https://www.gnu.org/software/grub/) (tested with
  2:2.06.r261.g2f4430cc0-1)

``` sh
zig build mkiso
```

### Run bootable ISO

#### Requires

* [zig](https://ziglang.org/) compiler v0.10 (tested with
  0.10.0-dev.2977+7d2e14267)
* [qemu-system-i386](https://www.qemu.org/) (tested with 7.0.0)

``` sh
zig build runiso
```
