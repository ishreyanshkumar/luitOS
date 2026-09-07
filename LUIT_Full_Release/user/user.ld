OUTPUT_ARCH("riscv")
ENTRY(_start)
SECTIONS {
  . = 0x1000;                 /* user programs load low; kernel lives at 2GB+ */
  .text : { *(.text.start) *(.text .text.*) }
  .rodata : { *(.rodata .rodata.*) }
  .data : { *(.data .data.*) }
  .bss : { *(.bss .bss.* COMMON) }
}
