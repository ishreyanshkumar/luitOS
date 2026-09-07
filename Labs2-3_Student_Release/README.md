# CS3106L — Labs 2 & 3 Student Release

*BrahmaputraOS / Luit · Dr. Satyajit Das · Department of Computer Science and Engineering · IIT Guwahati*

This package contains everything you need to understand and complete **Lab 2
(Kernel Tracing)** and **Lab 3 (Versioned Shared Info Page)**, including a
step-by-step GDB practice session.

## What's inside

    luit/                         the complete, bootable Luit teaching base (build with `make`)
    STUDENT_GUIDES/
      Luit_GDB_Practice_Labs2_3.pdf     <-- START HERE: the guided GDB session
      Luit_GDB_Practice_Labs2_3.docx
      Lab2_Kernel_Tracing_Spec.md       full Lab 2 specification
      Lab3_Shared_Info_Page_Spec.md     full Lab 3 specification

## Getting started

1. Build and boot the system to confirm your toolchain works:

       cd luit
       make
       make qemu            # boots Luit; you get a `luit$` shell. Exit: Ctrl-A then X

2. Work through **`STUDENT_GUIDES/Luit_GDB_Practice_Labs2_3.pdf`**. It is a
   hands-on session: open two terminals, boot under the debugger with
   `make qemu-gdb`, attach with `gdb-multiarch kernel.elf`, and type every
   command yourself. It walks you through system calls, page tables, and the
   process table — grounded in Luit's real source — and ends with a guided
   sequence for each of Lab 2 and Lab 3.

3. Read the two lab specifications in `STUDENT_GUIDES/`.

## Prerequisites

    riscv64-unknown-elf-gcc      the RISC-V cross compiler
    qemu-system-riscv64          the emulator
    gdb-multiarch                RISC-V-aware GDB (or riscv64-unknown-elf-gdb)

If GDB refuses to auto-load Luit's `.gdbinit`, see Section 0.2 of the practice
guide (on the department lab machines this is already configured).

## Grading

The public checks for these labs run via:

    make grade LAB=2
    make grade LAB=3

## Academic integrity

You must implement Labs 2 and 3 yourself. Every lab records an LLM-use
declaration; the vivas target the exact design decisions (per-hart ring design,
seqlock barrier placement) that a copied solution cannot defend. See each spec's
"LLM-use declaration" and "Anti-copying check" sections.
