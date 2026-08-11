# Implementation note.
# Because the kernel is mapped into every user page table, we do NOT switch
# satp here and we need no trampoline. We only switch STACKS.
# sscratch holds &p->tf on entry from user mode.
        .globl uservec
        .globl userret
        .globl usertrap
        .align 4
uservec:
        csrrw   a0, sscratch, a0        # a0 = &tf ; sscratch = user's a0

        sd ra,  40(a0)
        sd sp,  48(a0)
        sd gp,  56(a0)
        sd tp,  64(a0)
        sd t0,  72(a0)
        sd t1,  80(a0)
        sd t2,  88(a0)
        sd s0,  96(a0)
        sd s1,  104(a0)
        sd a1,  120(a0)
        sd a2,  128(a0)
        sd a3,  136(a0)
        sd a4,  144(a0)
        sd a5,  152(a0)
        sd a6,  160(a0)
        sd a7,  168(a0)
        sd s2,  176(a0)
        sd s3,  184(a0)
        sd s4,  192(a0)
        sd s5,  200(a0)
        sd s6,  208(a0)
        sd s7,  216(a0)
        sd s8,  224(a0)
        sd s9,  232(a0)
        sd s10, 240(a0)
        sd s11, 248(a0)
        sd t3,  256(a0)
        sd t4,  264(a0)
        sd t5,  272(a0)
        sd t6,  280(a0)

        csrr    t0, sscratch            # t0 = user's original a0
        sd      t0, 112(a0)             # tf->a0

        csrr    t1, sepc
        sd      t1, 24(a0)              # tf->epc = where user was

        ld      tp, 32(a0)              # restore our hartid into tp
        ld      sp, 8(a0)               # switch to the kernel stack
        ld      t1, 16(a0)              # tf->kernel_trap = &usertrap
        jr      t1

# void userret(struct trapframe *tf)  -- a0 = tf
userret:
        csrw    sscratch, a0            # so the next uservec can find it

        ld t0,  24(a0)
        csrw    sepc, t0                # return to where the user left off

        ld ra,  40(a0)
        ld sp,  48(a0)
        ld gp,  56(a0)
        ld tp,  64(a0)
        ld t0,  72(a0)
        ld t1,  80(a0)
        ld t2,  88(a0)
        ld s0,  96(a0)
        ld s1,  104(a0)
        ld a1,  120(a0)
        ld a2,  128(a0)
        ld a3,  136(a0)
        ld a4,  144(a0)
        ld a5,  152(a0)
        ld a6,  160(a0)
        ld a7,  168(a0)
        ld s2,  176(a0)
        ld s3,  184(a0)
        ld s4,  192(a0)
        ld s5,  200(a0)
        ld s6,  208(a0)
        ld s7,  216(a0)
        ld s8,  224(a0)
        ld s9,  232(a0)
        ld s10, 240(a0)
        ld s11, 248(a0)
        ld t3,  256(a0)
        ld t4,  264(a0)
        ld t5,  272(a0)
        ld t6,  280(a0)

        ld a0,  112(a0)                 # finally, the user's a0 (syscall retval)
        sret
