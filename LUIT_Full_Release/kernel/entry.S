# Implementation note.
# a0 = hartid, a1 = physical address of the FDT blob. Both must survive to start().
.section .text.entry
.globl _entry
_entry:
        la      t0, boot_stacks
        li      t1, 16384
        addi    t2, a0, 1
        mul     t1, t1, t2
        add     sp, t0, t1      # sp = boot_stacks + (hartid+1)*16384
        mv      tp, a0          # tp = hartid, for mycpu()
        call    start
spin:   wfi
        j       spin

.section .bss
.align 12
.globl boot_stacks
boot_stacks:
        .space 16384 * 8
