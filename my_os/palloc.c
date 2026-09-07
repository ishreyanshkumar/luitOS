#include "types.h"
struct run {
		struct run* next;
};
struct {
		struct run* freelist;
} kmem;

/**
 * pfree
 * What it does: Returns a 4096-byte chunk of memory back to the Kernel's free list.
 * Why it exists: When a process dies or shrinks, its physical memory is no longer needed.
 * This function recycles that memory so other programs can use it later.
 */
void pfree(void* pa) {
	struct run* r = (struct run*)pa;
	r->next = kmem.freelist;
	kmem.freelist = r;
}

/**
 * palloc
 * What it does: Grabs a single 4096-byte chunk of free physical memory from the list and returns it.
 * Why it exists: Anytime the OS needs memory (to create a page table, to allocate a trapframe,
 * or to give RAM to a user program), it asks this function for a raw physical page.
 */
void* palloc() {
	struct run* r = kmem.freelist;
	if (r) {
		kmem.freelist = r->next;
	}
	return (void*)r;
}
extern char kernel_end[];

/**
 * kinit
 * What it does: Runs once at boot to divide all the free physical RAM into 4096-byte chunks
 * and puts them onto the global free list.
 * Why it exists: The OS needs to know exactly what memory is available to hand out.
 * This builds the "bank" of free memory, starting immediately after where the Kernel's code ends,
 * all the way up to the 128MB limit.
 */
void kinit() {
	uint64 p = (uint64)kernel_end;
	p = (p + PGSIZE - 1) & ~(PGSIZE - 1);
	uint64 PHYSTOP = 0x88000000;
	for (; p + PGSIZE <= PHYSTOP; p += PGSIZE) {
		pfree((void*)p);
	}
}
