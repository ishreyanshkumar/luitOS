#include "proc.h"
#include "types.h"
#define NPROC 64
extern void* palloc();
extern void mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm);
extern pagetable_t kernel_pagetable;
extern pagetable_t uvmcreate(void);
extern void usertrapret(void);
extern void usertrap(void);
extern int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz);
extern uint64 uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz);
extern uint64 uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz);
struct proc proc[NPROC];
struct context scheduler_context;
extern void swtch(struct context* old, struct context* new);

/**
 * myproc
 * What it does: Finds and returns the pointer to the currently running process on this CPU.
 * Why it exists: Many kernel functions (like system calls or trap handlers) need to know
 * "which process triggered this?" so they can read or modify its specific data.
 */
struct proc* myproc(void) {
	for (int i = 0; i < NPROC; i++) {
		if (proc[i].state == RUNNING) {
			return &proc[i];
		}
	}
	return 0;
}

/**
 * procinit
 * What it does: Runs once when the OS boots up to initialize the process table.
 * Why it exists: It makes sure every single process slot is cleanly marked as UNUSED,
 * so the OS knows they are all completely free and ready to be used.
 */
void procinit(void) {
	for (struct proc* p = proc; p < &proc[NPROC]; p++) {
		p->state = UNUSED;
	}
}

/**
 * allocproc
 * What it does: Scans the process table to find an empty (UNUSED) slot, claims it,
 * and sets up its basic memory structures (like a page table and trapframe).
 * Why it exists: Whenever the OS needs to create a brand new process (like during boot
 * or when a user calls fork()), this function handles the heavy lifting of preparing it.
 */
struct proc* allocproc() {
	struct proc* p;
	for (p = proc; p < &proc[NPROC]; p++) {
		if (p->state == UNUSED)
			goto found;
	}
	return 0;
found:
	p->state = USED;
	p->trapframe = (struct trapframe*)palloc();
	p->pagetable = uvmcreate();
	p->kstack = (uint64)palloc();
	for (int i = 0; i < 14; i++) {
		((uint64*)&p->context)[i] = 0;
	}
	p->context.ra = (uint64)usertrapret;
	p->context.sp = p->kstack + PGSIZE;
	return p;
}

/**
 * fork
 * What it does: Creates an exact clone of a parent process, copying its memory,
 * its variables, and its CPU registers into a new child process.
 * Why it exists: This is the fundamental way new programs are spawned in Unix/Linux OSes.
 * The child process continues running from the exact same line of code as the parent!
 */
int fork(struct proc* p) {
	struct proc* np = allocproc();
	if (np == 0)
		return -1;
	if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
		return -1;
	np->sz = p->sz;
	for (int i = 0; i < sizeof(struct trapframe); i++) {
		((char*)np->trapframe)[i] = ((char*)p->trapframe)[i];
	}
	np->trapframe->a0 = 0;
	np->state = RUNNABLE;
	return np - proc;
}

/**
 * growproc
 * What it does: Increases or decreases the total amount of memory a process owns.
 * Why it exists: User programs often need to dynamically allocate more memory
 * (like using malloc() in C). This function fulfills that request by giving them physical RAM.
 */
int growproc(struct proc* p, int n) {
	uint64 sz = p->sz;
	if (n > 0) {
		if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
			return -1;
	} else if (n < 0) {
		sz = uvmdealloc(p->pagetable, sz, sz + n);
	}
	p->sz = sz;
	return 0;
}
unsigned char initcode[] = {
	0x85, 0x48,
	0x73, 0x00, 0x00, 0x00,
	0xa9, 0x48,
	0x73, 0x00, 0x00, 0x00,
	0xed, 0xbf
};

/**
 * userinit
 * What it does: Manually injects the very first user program (Process 0) into memory and queues it.
 * Why it exists: An OS is useless if it has no user programs to run. Since there are no
 * programs running yet to call fork(), the OS must handcraft the first one during boot!
 */
void userinit(void) {
	struct proc* p = allocproc();
	char* mem = palloc();
	for (int i = 0; i < sizeof(initcode); i++) {
		mem[i] = initcode[i];
	}
	mappages(p->pagetable, 0x0, 4096, (uint64)mem, PTE_R | PTE_W | PTE_X | PTE_U);
	p->sz = 4096;
	p->trapframe->epc = 0x0;
	p->state = RUNNABLE;
}

/**
 * scheduler
 * What it does: An infinite loop that constantly scans the process table looking for RUNNABLE processes.
 * When it finds one, it teleports the CPU into that process using swtch().
 * Why it exists: This is the beating heart of the OS. It allows multitasking by rapidly
 * switching the CPU between different user programs, making it look like they run simultaneously.
 */
void scheduler(void) {
	struct proc* p;
	for (;;) {
		for (p = proc; p < &proc[NPROC]; p++) {
			if (p->state == RUNNABLE) {
				p->state = RUNNING;
				w_satp(MAKE_SATP(p->pagetable));
				sfence_vma();
				swtch(&scheduler_context, &p->context);
				w_satp(MAKE_SATP(kernel_pagetable));
				sfence_vma();
			}
		}
	}
}
