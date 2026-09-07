#include "proc.h"
#include "types.h"
extern void kernelvec();
extern void syscall();
extern void usertrap();
extern pagetable_t kernel_pagetable;
extern void uservec();
extern void userret(struct trapframe* tf);
extern void print_string(const char* s);

/**
 * trapinithart
 * What it does: Tells the CPU hardware where to find the kernel's trap handler (kernelvec).
 * Why it exists: If the kernel divides by zero, accesses bad memory, or receives a timer
 * interrupt while running in Supervisor Mode, the CPU needs to know exactly what code to jump to.
 */
void trapinithart() {
	w_stvec((uint64)kernelvec);
}

/**
 * usertrapret
 * What it does: Prepares the CPU and memory to jump safely back into a user space program.
 * Why it exists: The kernel runs in a highly privileged mode with its own page table and stack.
 * Before returning to the user, we must carefully configure the CPU to switch back to the user's
 * page table, drop to lowest privilege, and tell the CPU what to do if the user traps again.
 */
void usertrapret() {
	struct proc* p = myproc();
	if (!p)
		return;
	uint64 x = r_sstatus();
	x &= ~(1ULL << 1);
	w_sstatus(x);
	w_stvec((uint64)uservec);
	p->trapframe->kernel_satp = MAKE_SATP(kernel_pagetable);
	p->trapframe->kernel_sp = p->kstack + 4096;
	p->trapframe->kernel_trap = (uint64)usertrap;
	p->trapframe->kernel_hartid = 0;
	w_sscratch((uint64)p->trapframe);
	x = r_sstatus();
	x &= ~(1ULL << 8);
	w_sstatus(x);
	w_sepc(p->trapframe->epc);
	userret(p->trapframe);
}

/**
 * usertrap
 * What it does: This is the main C handler for all exceptions, interrupts, and system calls
 * that happen while a user program is running.
 * Why it exists: When a user program crashes or calls 'ecall', the assembly code (uservec)
 * saves the registers and jumps here. This C code decides what to do: handle a system call,
 * kill a crashing program, or handle a hardware interrupt.
 */
void usertrap() {
	w_stvec((uint64)kernelvec);
	struct proc* p = myproc();
	if (!p)
		return;
	p->trapframe->epc = r_sepc();
	uint64 scause = r_scause();
	int is_interrupt = (scause & (1ULL << 63)) != 0;
	uint64 cause_num = scause & 0xFF;
	if (is_interrupt) {
		print_string("USER TRAP! Unhandled Interrupt.\n");
		while (1) { }
	} else if (cause_num == 8) {
		p->trapframe->epc += 4;
		syscall();
		p->state = RUNNABLE;
		extern struct context scheduler_context;
		extern void swtch(struct context * old, struct context * new);
		swtch(&p->context, &scheduler_context);
	} else {
		print_string("USER TRAP! CPU panicked with exception.\n");
		while (1) { }
	}
	usertrapret();
}

/**
 * kerneltrap
 * What it does: This is the main C handler for all exceptions and interrupts that happen
 * while the KERNEL ITSELF is running (Supervisor Mode).
 * Why it exists: If the Kernel crashes, we jump here (usually to panic and halt the system).
 * If the Kernel receives a timer interrupt while running, we jump here to save state.
 */
void kerneltrap() {
	uint64 sepc = r_sepc();
	uint64 sstatus = r_sstatus();
	uint64 scause = r_scause();
	int is_interrupt = (scause & (1ULL << 63)) != 0;
	if (is_interrupt) {
		print_string("KERNEL TRAP! Unhandled Interrupt.\n");
		while (1) { }
	} else {
		print_string("KERNEL TRAP! CPU panicked with exception.\n");
		while (1) { }
	}
	w_sepc(sepc);
	w_sstatus(sstatus);
}
