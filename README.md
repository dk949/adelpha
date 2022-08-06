# Adelpha

Status: vapourware

Adelpha is a bare-bones exo-kernel with a small operating system on top of it.

Currently there are no particular goals, just get something working :)

## Build and run

### Build

#### Requires

* Zig 10 compiler (tested with 0.10.0-dev.2977+7d2e14267)

``` sh
zig build
```

### Run

#### Requires

* Zig 10 compiler (tested with 0.10.0-dev.2977+7d2e14267)
* qemu-system-i386 (tested with 7.0.0)

``` sh
zig build run
```

### Make bootable ISO

#### Requires

* Zig 10 compiler (tested with 0.10.0-dev.2977+7d2e14267)
* xorriso (tested with 1.5.4)
* mformat (tested with 4.0.40)
* grub-mkrescue (tested with 2:2.06.r261.g2f4430cc0-1)

``` sh
zig build mkiso
```

### Run bootable ISO

#### Requires

* Zig 10 compiler (tested with 0.10.0-dev.2977+7d2e14267)
* qemu-system-i386 (tested with 7.0.0)

``` sh
zig build runiso
```
