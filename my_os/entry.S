.section .text.entry
.globl _entry

# _entry
# What it does: The absolute very first instruction the CPU executes when the OS boots up.
# It sets up a stack pointer (sp) for the first CPU core so that we can call C functions, 
# and then it jumps into the C code at main.c's 'start' function.
# Why it exists: C code requires a stack to work (for local variables and function calls). 
# We have to write this tiny bit of Assembly to manually create that stack before jumping to C.
_entry:
    la t0, boot_stacks
    li t1, 16384
    addi t2, a0, 1
    mul t1, t1, t2
    add sp, t0, t1
    call start
spin:
    wfi
    j spin
.section .bss
.align 16
.globl boot_stacks
boot_stacks:
    .space 131072
