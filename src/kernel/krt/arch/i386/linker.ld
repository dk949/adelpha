/*https://sourceware.org/binutils/docs/ld/Basic-Script-Concepts.html*/
ENTRY(_start) /* The bootloader will look at this image and start execution at the symbol designated at the entry point. */

SECTIONS {
/* Tell where the various sections of the object files will be put in the final kernel image. */
	/* Begin putting sections at 1 MiB, a conventional place for kernels to be
	   loaded at by the bootloader. */
	. = 1M;

	.text : ALIGN(4K) {
		KEEP(*(.multiboot))
		*(.text) /* First put the multiboot header, as it is required to be put very early early in the image or the bootloader won't recognize the file format. Next we'll put the .text section. */
	}

	.rodata : ALIGN(4K) {
	/* Read-only data. */
		*(.rodata)
	}

	.data : ALIGN(4K) {
	/* Read-write data (initialized) */
		*(.data)
	}

	/* Read-write data (uninitialized) and stack */
	.bss : ALIGN(4K) {
		*(COMMON) /*wild card for all section considered common*/
		*(.bss)
	}

	/* The compiler may produce other sections, put them in the proper place in
	   in this file, if you'd like to include them in the final kernel. */
}
