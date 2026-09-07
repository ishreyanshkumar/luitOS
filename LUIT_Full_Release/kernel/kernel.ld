OUTPUT_ARCH("riscv")
ENTRY(_entry)
SECTIONS {
  . = 0x80200000;
  .text : { *(.text.entry) *(.text .text.*) }
  . = ALIGN(0x1000);
  etext = .;
  .rodata : { *(.rodata .rodata.*) }
  . = ALIGN(0x1000);
  .data : { *(.data .data.*) }
  . = ALIGN(0x1000);
  .bss : { bss_start = .; *(.bss .bss.* COMMON) bss_end = .; }
  . = ALIGN(0x1000);
  kernel_end = .;
}
