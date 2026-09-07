.globl uservec
.globl userret
.align 4

# uservec
# What it does: The first assembly code that runs when a user program traps into the kernel 
# (e.g. through a system call or interrupt). It swaps the user stack pointer for the 
# kernel trapframe pointer, saves all 32 user registers into the trapframe, and jumps 
# to the C function 'usertrap'.
# Why it exists: User space has no privileges. To safely transition to the kernel, 
# we must meticulously save exactly what the user was doing so we can resume them later.
uservec:
    csrrw a0, sscratch, a0
    sd ra, 40(a0)
    sd sp, 48(a0)
    sd gp, 56(a0)
    sd tp, 64(a0)
    sd t0, 72(a0)
    sd t1, 80(a0)
    sd t2, 88(a0)
    sd s0, 96(a0)
    sd s1, 104(a0)
    sd a1, 120(a0)
    sd a2, 128(a0)
    sd a3, 136(a0)
    sd a4, 144(a0)
    sd a5, 152(a0)
    sd a6, 160(a0)
    sd a7, 168(a0)
    sd s2, 176(a0)
    sd s3, 184(a0)
    sd s4, 192(a0)
    sd s5, 200(a0)
    sd s6, 208(a0)
    sd s7, 216(a0)
    sd s8, 224(a0)
    sd s9, 232(a0)
    sd s10, 240(a0)
    sd s11, 248(a0)
    sd t3, 256(a0)
    sd t4, 264(a0)
    sd t5, 272(a0)
    sd t6, 280(a0)
    csrr t0, sscratch
    sd t0, 112(a0)
    csrr t1, sepc
    sd t1, 24(a0)
    ld tp, 32(a0)
    ld sp, 8(a0)
    ld t1, 16(a0)
    jr t1

# userret
# What it does: The assembly code that runs right before jumping back to a user program. 
# It takes the trapframe, restores all 32 user registers from it, puts the trapframe 
# pointer back into the sscratch register, and issues the 'sret' instruction.
# Why it exists: This is the exact mirror image of uservec. It carefully puts the CPU 
# back exactly the way the user left it, and drops privilege back to User Mode.
userret:
    csrw sscratch, a0
    ld t0, 24(a0)
    csrw sepc, t0
    ld ra, 40(a0)
    ld sp, 48(a0)
    ld gp, 56(a0)
    ld tp, 64(a0)
    ld t0, 72(a0)
    ld t1, 80(a0)
    ld t2, 88(a0)
    ld s0, 96(a0)
    ld s1, 104(a0)
    ld a1, 120(a0)
    ld a2, 128(a0)
    ld a3, 136(a0)
    ld a4, 144(a0)
    ld a5, 152(a0)
    ld a6, 160(a0)
    ld a7, 168(a0)
    ld s2, 176(a0)
    ld s3, 184(a0)
    ld s4, 192(a0)
    ld s5, 200(a0)
    ld s6, 208(a0)
    ld s7, 216(a0)
    ld s8, 224(a0)
    ld s9, 232(a0)
    ld s10, 240(a0)
    ld s11, 248(a0)
    ld t3, 256(a0)
    ld t4, 264(a0)
    ld t5, 272(a0)
    ld t6, 280(a0)
    ld a0, 112(a0)
    sret
