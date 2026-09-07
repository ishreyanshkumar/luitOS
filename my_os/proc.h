#include "riscv.h"
#include "types.h"
/**
 * procstate
 * What it does: Defines the possible lifecycle states a process can be in.
 * Why it exists: The scheduler uses this to know if a process is ready to run, 
 * already running, or unused and available to be recycled.
 */
enum procstate { UNUSED,
	USED,
	SLEEPING,
	RUNNABLE,
	RUNNING,
	ZOMBIE };
/**
 * context
 * What it does: Saves the CPU's core registers for kernel threads.
 * Why it exists: When the scheduler switches between two kernel threads (like from 
 * process A's kernel stack to the scheduler's kernel stack), it saves the old registers 
 * here and loads the new registers from another context structure.
 */
struct context {
		uint64 ra;
		uint64 sp;
		uint64 s0;
		uint64 s1;
		uint64 s2;
		uint64 s3;
		uint64 s4;
		uint64 s5;
		uint64 s6;
		uint64 s7;
		uint64 s8;
		uint64 s9;
		uint64 s10;
		uint64 s11;
};

/**
 * trapframe
 * What it does: Saves all 32 of the user's CPU registers when a trap occurs.
 * Why it exists: When a user program is interrupted (e.g., by a timer or system call), 
 * all its variables (which live in CPU registers) must be saved immediately to memory, 
 * so the kernel doesn't overwrite them. When resuming the program, the kernel restores 
 * them from this trapframe.
 */
struct trapframe {
		uint64 kernel_satp;
		uint64 kernel_sp;
		uint64 kernel_trap;
		uint64 epc;
		uint64 kernel_hartid;
		uint64 ra;
		uint64 sp;
		uint64 gp;
		uint64 tp;
		uint64 t0;
		uint64 t1;
		uint64 t2;
		uint64 s0;
		uint64 s1;
		uint64 a0;
		uint64 a1;
		uint64 a2;
		uint64 a3;
		uint64 a4;
		uint64 a5;
		uint64 a6;
		uint64 a7;
		uint64 s2;
		uint64 s3;
		uint64 s4;
		uint64 s5;
		uint64 s6;
		uint64 s7;
		uint64 s8;
		uint64 s9;
		uint64 s10;
		uint64 s11;
		uint64 t3;
		uint64 t4;
		uint64 t5;
		uint64 t6;
};

/**
 * proc
 * What it does: The Process Control Block (PCB). It holds everything the OS needs to know about a specific process.
 * Why it exists: This is the OS's representation of a running program. It keeps track of the process's 
 * state, memory (page table size and root), trapframe, and kernel stack. 
 */
struct proc {
		enum procstate state;
		int pid;
		uint64 sz;
		pagetable_t pagetable;
		struct trapframe* trapframe;
		uint64 kstack;
		struct context context;
};
struct proc* myproc(void);
