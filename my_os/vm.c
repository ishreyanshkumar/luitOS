#include "riscv.h"
#include "types.h"
extern void* palloc();
#define MMIO_OFFSET 0x100000000UL
pagetable_t kernel_pagetable;

/**
 * memset
 * What it does: Fills a block of memory with a specific value (usually zeros).
 * Why it exists: When the OS allocates new memory, it is full of random garbage data left
 * over from whatever used it last. We must zero it out to prevent security leaks and weird bugs.
 */
void memset(void* dst, int c, uint32 n) {
	char* cdst = (char*)dst;
	for (uint32 i = 0; i < n; i++) {
		cdst[i] = c;
	}
}

/**
 * memmove
 * What it does: Safely copies data from one area of memory to another.
 * Why it exists: Used all over the OS for duplicating memory (like when copying a parent
 * process's memory to a child process during fork).
 */
void memmove(void* dst, const void* src, uint32 n) {
	const char* s = src;
	char* d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else {
		while (n-- > 0)
			*d++ = *s++;
	}
}

/**
 * walk
 * What it does: Walks down the 3-level RISC-V Page Table tree to find the Page Table Entry (PTE)
 * for a specific Virtual Address. If the middle levels don't exist yet, it can optionally allocate them.
 * Why it exists: The OS frequently needs to map new virtual addresses or check the physical address
 * behind a virtual address. This function does the heavy lifting of navigating the tree structure.
 */
pte_t* walk(pagetable_t pagetable, uint64 va, int alloc) {
	for (int level = 2; level > 0; level--) {
		int index = PX(level, va);
		pte_t* pte = &pagetable[index];
		if (*pte & PTE_V) {
			pagetable = (pagetable_t)PTE2PA(*pte);
		} else {
			if (!alloc)
				return 0;
			pagetable = (pagetable_t)palloc();
			if (pagetable == 0)
				return 0;
			memset(pagetable, 0, 4096);
			*pte = PA2PTE(pagetable) | PTE_V;
		}
	}
	return &pagetable[PX(0, va)];
}

/**
 * mappages
 * What it does: Creates memory mappings for a range of virtual addresses to physical addresses.
 * Why it exists: This is how the OS actually populates page tables. You tell it "Map Virtual Address
 * X to Physical Address Y", and it uses walk() to find the entry and sets the permissions (like Read/Write).
 */
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm) {
	uint64 a, last;
	pte_t* pte;
	a = va & ~(PGSIZE - 1);
	last = (va + size - 1) & ~(PGSIZE - 1);
	while (1) {
		pte = walk(pagetable, a, 1);
		if (pte == 0)
			return -1;
		if (*pte & PTE_V)
			return -1;
		*pte = PA2PTE(pa) | perm | PTE_V;
		if (a == last)
			break;
		a += PGSIZE;
		pa += PGSIZE;
	}
	return 0;
}

/**
 * kvminit
 * What it does: Creates the central Kernel Page Table that maps the entire physical RAM and hardware devices.
 * Why it exists: Before turning on the MMU, the Kernel must create a map for itself so it doesn't
 * crash immediately when Virtual Memory gets enabled. It maps 100% of RAM so it has "God Mode" access to everything.
 */
void kvminit() {
	kernel_pagetable = (pagetable_t)palloc();
	memset(kernel_pagetable, 0, PGSIZE);
	mappages(kernel_pagetable, 0x10000000L + MMIO_OFFSET, PGSIZE, 0x10000000L, PTE_R | PTE_W);
	uint64 RAM_START = 0x80000000L;
	uint64 RAM_SIZE = 128 * 1024 * 1024;
	mappages(kernel_pagetable, RAM_START, RAM_SIZE, RAM_START, PTE_R | PTE_W | PTE_X);
}

/**
 * kvminithart
 * What it does: Flips the switch! Tells the CPU hardware to turn ON the Memory Management Unit (MMU).
 * Why it exists: Once the MMU is on, every single address the CPU touches becomes a "Virtual Address"
 * that goes through the page table. This provides memory protection and isolation.
 */
void kvminithart() {
	w_satp(MAKE_SATP(kernel_pagetable));
	sfence_vma();
}

/**
 * uvmcreate
 * What it does: Creates a brand new, empty page table for a User process.
 * Why it exists: Every user program needs its own isolated universe of memory. This creates
 * the blank slate. It also links the Kernel's memory into the top half of the user's page table!
 */
pagetable_t uvmcreate() {
	pagetable_t pt = (pagetable_t)palloc();
	if (!pt)
		return 0;
	for (int i = 0; i < 512; i++)
		pt[i] = 0;
	for (int i = 2; i < 512; i++)
		pt[i] = kernel_pagetable[i];
	return pt;
}

/**
 * uvmcopy
 * What it does: Deep copies an entire User Page Table from an old process to a new process.
 * Why it exists: Used by fork()! When a process clones itself, we don't just copy the page table map,
 * we actually allocate brand new physical RAM chips and copy the raw bytes over so the child is totally independent.
 */
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz) {
	pte_t* pte;
	uint64 pa, i;
	int flags;
	char* mem;
	for (i = 0; i < sz; i += PGSIZE) {
		if ((pte = walk(old, i, 0)) == 0)
			continue;
		if ((*pte & PTE_V) == 0)
			continue;
		pa = PTE2PA(*pte);
		flags = (*pte) & 0x3FF;
		mem = palloc();
		if (mem == 0)
			return -1;
		memmove(mem, (char*)pa, PGSIZE);
		if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
			return -1;
	}
	return 0;
}

/**
 * uvmalloc
 * What it does: Allocates new physical memory pages and maps them into a user's page table to grow it.
 * Why it exists: Used when a user program asks for more heap memory. It grabs raw pages from palloc()
 * and maps them into the user's virtual space.
 */
uint64 uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz) {
	char* mem;
	uint64 a;
	if (newsz < oldsz)
		return oldsz;
	oldsz = (oldsz + (PGSIZE - 1)) & ~(PGSIZE - 1);
	for (a = oldsz; a < newsz; a += PGSIZE) {
		mem = palloc();
		if (mem == 0)
			return 0;
		memset(mem, 0, PGSIZE);
		if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W | PTE_X | PTE_R | PTE_U) != 0)
			return 0;
	}
	return newsz;
}

/**
 * uvmdealloc
 * What it does: Unmaps memory pages to shrink a user's page table.
 * Why it exists: Used when a user program frees memory, or when the process is being killed
 * and its memory needs to be cleaned up. (Currently unimplemented beyond simple returning the old size).
 */
uint64 uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz) {
	if (newsz >= oldsz)
		return oldsz;
	return newsz;
}
