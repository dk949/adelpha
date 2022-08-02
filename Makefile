all:
	zig build-exe hellos.zig -target i386-freestanding -T linker.ld
