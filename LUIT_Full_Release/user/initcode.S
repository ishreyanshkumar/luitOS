# The first user code ever executed. Its only job: exec("/init").
.globl start
start:
        la      a0, init
        la      a1, argv
        li      a7, 7           # SYS_exec
        ecall
        # exec failed - loop forever rather than run off the end
exit_loop:
        li      a7, 2           # SYS_exit
        li      a0, 1
        ecall
        j exit_loop

init:   .string "/init\0"
.p2align 3
argv:   .dword init
        .dword 0
