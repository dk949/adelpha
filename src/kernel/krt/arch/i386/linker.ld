/*https://sourceware.org/binutils/docs/ld/Basic-Script-Concepts.html*/
ENTRY(_start) /*entry symbol*/

SECTIONS {
    /* (not 100% sure) set the starting location, all sections will be placed from 1M onwards */
	. = 1M;

	.text : ALIGN(4K) {
		KEEP(*(.multiboot))
		*(.text) /*place .text from all files into this output section*/
	}

	.rodata : ALIGN(4K) {
		*(.rodata)
	}

	.data : ALIGN(4K) {
		*(.data)
	}

	.bss : ALIGN(4K) {
		*(COMMON) /*wild card for all section considered common*/
		*(.bss)
	}
}
