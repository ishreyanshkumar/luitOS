/* L5 / L12 - TRAP HANDLING. */
#include "types.h"
#include "defs.h"
#include "hal.h"

struct spinlock tickslock;
uint64 ticks;

extern void kernelvec(void);
extern void uservec(void);
extern void userret(struct trapframe *);

void hal_intc_enable_hart(int hart, int irq);   /* from the HAL backend's plic.c */

void trapinit_hart(void)
{
    w_stvec((uint64)kernelvec);

    /* Interrupt sources come from the DEVICE TREE, not from #defines.
     * (fdt.uart_irq is 10 on qemu virt - but we asked, we did not assume.) */
    hal_intc_enable(fdt.uart_irq);              /* priority 1; 0 = never fires */
    hal_intc_hart_init(hal_hart_id());
    hal_intc_enable_hart(hal_hart_id(), fdt.uart_irq);
    if (hal_block_irq()) {
        hal_intc_enable(hal_block_irq());
        hal_intc_enable_hart(hal_hart_id(), hal_block_irq());
    }
    w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    hal_timer_next(1000000);
    intr_on();
}

/* Returns: 2 = timer, 1 = other device, 0 = not an interrupt (an exception). */
static int devintr(void)
{
    uint64 scause = r_scause();

    if (!(scause & 0x8000000000000000UL)) return 0;   /* top bit = interrupt */

    uint64 code = scause & 0xff;

    if (code == 9) {                     /* supervisor external -> PLIC */
        int irq = hal_intc_claim();
        if (irq == fdt.uart_irq) {
            int c = hal_console_getc();
            if (c != -1) consoleintr(c);
        } else if (irq && irq == hal_block_irq()) {
            hal_block_intr();
        } else if (irq) {
            printf("devintr: unexpected PLIC irq %d\n", irq);
        }
        if (irq) hal_intc_complete(irq);
        return 1;
    }
    if (code == 5) {
        if (hal_hart_id() == 0) {        /* only hart 0 keeps the clock */
            acquire(&tickslock);
            ticks++;
            wakeup(&ticks);
            release(&tickslock);
        }
        hal_timer_next(1000000);
        return 2;
    }
    return 0;
}

static const char *cause_str(uint64 c)
{
    switch (c) {
    case 0:  return "instruction address misaligned";
    case 1:  return "instruction access fault";
    case 2:  return "illegal instruction";
    case 3:  return "breakpoint";
    case 5:  return "load access fault";
    case 7:  return "store access fault";
    case 8:  return "ecall from user";
    case 12: return "instruction page fault";
    case 13: return "load page fault";
    case 15: return "store page fault";
    default: return "unknown";
    }
}

/* Trap while already in the kernel. */
void kerneltrap(void)
{
    uint64 sepc     = r_sepc();
    uint64 sstatus  = r_sstatus();
    uint64 scause   = r_scause();

    if ((sstatus & SSTATUS_SPP) == 0) panic("kerneltrap: not from S-mode");
    if (intr_get()) panic("kerneltrap: interrupts were enabled");

    int which = devintr();
    if (which == 0) {
        printf("\nkerneltrap: %s\n", cause_str(scause & 0xff));
        panic("kernel exception");
    }
    /* Timer: give up the CPU, but only if we are running a process. */
    if (which == 2 && myproc() && myproc()->state == RUNNING)
        yield();

    /* yield() may have run other code; restore what sret needs. */
    w_sepc(sepc);
    w_sstatus(sstatus);
}

/* Trap from user mode. Called from uservec with our kernel stack installed. */
void usertrap(void)
{
    if (r_sstatus() & SSTATUS_SPP) panic("usertrap: came from S-mode");

    w_stvec((uint64)kernelvec);      /* while in the kernel, kernel traps apply */

    struct proc *p = myproc();
    p->tf->epc = r_sepc();

    uint64 scause = r_scause();

    if (scause == 8) {               /* ecall: a system call */
        if (p->killed) exit(-1);
        p->tf->epc += 4;             /* return AFTER the ecall, not onto it */
        intr_on();                   /* syscalls may sleep; let interrupts in */
        syscall();
    } else if (scause == 15 || scause == 13) {   /* store / load page fault */
        /* THE PAGE-FAULT HOOK. In the baseline, a user page fault is always
         * fatal to the process. Copy-on-write fork (Lab 5) resolves write
         * faults on PTE_COW pages here; mmap (Lab 10) resolves faults inside
         * mapped regions here; the lazy-allocation challenge exercise, if you
         * attempt it, lands here too. This is the most-visited line in the course. */
        uint64 va = r_stval();
        if (scause == 15 && cowfault(p->pagetable, va) == 0) {
            /* COW fault handled */
        } else if (mmap_fault(p, va) == 0) {
            /* Lab 10: mmap fault handled (lazy fault-in) */
        } else {
            printf("usertrap: pid %d %s at va %p (sepc %p) - killing\n",
                   p->pid, cause_str(scause), va, p->tf->epc);
            p->killed = 1;
        }
    } else {
        int which = devintr();
        if (which == 0) {
            printf("usertrap: pid %d unexpected %s (scause %p, stval %p) - killing\n",
                   p->pid, cause_str(scause & 0xff), scause, r_stval());
            p->killed = 1;
        }
        if (which == 2 && p->state == RUNNING) {
            alarm_tick();               /* Lab 4: maybe deliver a timer event */
            yield();
        }
    }

    if (p->killed) exit(-1);
    usertrapret();
}

void usertrapret(void)
{
    struct proc *p = myproc();

    intr_off();                       /* no interrupts between stvec and sret */
    w_stvec((uint64)uservec);

    p->tf->kernel_satp   = r_satp();
    p->tf->kernel_sp     = p->kstack + 4 * PGSIZE;   /* top of the kernel stack */
    p->tf->kernel_trap   = (uint64)usertrap;
    p->tf->kernel_hartid = r_tp();

    uint64 x = r_sstatus();
    x &= ~SSTATUS_SPP;                /* SPP=0 -> sret drops us to U-mode */
    x |= SSTATUS_SPIE;                /* re-enable interrupts in user mode */
    w_sstatus(x);
    w_sepc(p->tf->epc);

    userret(p->tf);
}
