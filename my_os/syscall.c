#include "proc.h"
#include "types.h"
extern int fork(struct proc* p);
extern int growproc(struct proc* p, int n);
extern void print_string(const char* s);
extern struct proc proc[];

/**
 * sys_fork
 * What it does: The system call implementation for fork(). It tells the Kernel to clone the current process.
 * Why it exists: When a user program runs the "ecall" assembly instruction with a7 = 1,
 * the trap handler routes it here to actually perform the process duplication.
 */
uint64 sys_fork(void) {
	print_string("-> SYS_fork: Parent Process is cloning itself!\n");
	return fork(myproc());
}

/**
 * sys_growproc
 * What it does: The system call implementation for growing the process memory.
 * Why it exists: It acts as an interface for user programs to request more heap memory from the kernel.
 */
uint64 sys_growproc(void) {
	int n = myproc()->trapframe->a0;
	return growproc(myproc(), n);
}

/**
 * sys_yield
 * What it does: The system call implementation for yield(). It tells the scheduler "I am done for now."
 * Why it exists: If a program has nothing to do (or is just being polite), it can voluntarily
 * pause itself and let another program run on the CPU.
 */
uint64 sys_yield(void) {
	struct proc* p = myproc();
	if ((p - proc) == 0) {
		print_string("Process 0 (Parent) is yielding the CPU...\n");
	} else {
		print_string("Process 1 (Child) is yielding the CPU...\n");
	}
	return 0;
}
static uint64 (*syscalls[])(void) = {
	[1] = sys_fork,
	[10] = sys_yield,
	[12] = sys_growproc,
};

/**
 * syscall
 * What it does: The main router for all system calls. It looks at the a7 register to find the
 * system call number, and then looks up the correct function in the syscalls array to run it.
 * Why it exists: User programs cannot call kernel functions directly (it's insecure).
 * Instead, they trap into the kernel, and this function acts as the secure middleman.
 */
void syscall(void) {
	struct proc* p = myproc();
	uint64 num = p->trapframe->a7;
	if (num > 0 && num < (sizeof(syscalls) / sizeof(syscalls[0])) && syscalls[num]) {
		p->trapframe->a0 = syscalls[num]();
	} else {
		print_string("UNKNOWN SYSCALL!\n");
		p->trapframe->a0 = -1;
	}
}
