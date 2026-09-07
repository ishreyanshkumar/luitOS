#include "types.h"
typedef uint64 pte_t;
typedef uint64* pagetable_t;
#define PTE_V (1L << 0)
#define PTE_R (1L << 1)
#define PTE_W (1L << 2)
#define PTE_X (1L << 3)
#define PTE_U (1L << 4)
#define PA2PTE(pa) ((((uint64)pa) >> 12) << 10)
#define PTE2PA(pte) (((pte) >> 10) << 12)
#define PX(level, va) ((((uint64)(va)) >> (12 + (9 * (level)))) & 0x1FF)
/**
 * w_satp
 * What it does: Writes a value to the Supervisor Address Translation and Protection (satp) register.
 * Why it exists: Used to tell the CPU hardware exactly where the root Page Table is located in RAM.
 */
static inline void w_satp(uint64 x) {
	asm volatile("csrw satp, %0" : : "r"(x));
}
/**
 * sfence_vma
 * What it does: Flushes the CPU's Translation Lookaside Buffer (TLB).
 * Why it exists: When we change the Page Table, the CPU might still be using old, cached mappings. 
 * This instruction forces the CPU to forget the old mappings and read the new ones.
 */
static inline void sfence_vma() {
	asm volatile("sfence.vma zero, zero");
}
#define SATP_SV39 (8L << 60)
#define MAKE_SATP(pagetable) (SATP_SV39 | (((uint64)pagetable) >> 12))
/**
 * w_stvec
 * What it does: Writes a memory address to the Supervisor Trap Vector (stvec) register.
 * Why it exists: Tells the CPU exactly where to jump to (which code to run) if a trap, 
 * exception, or interrupt occurs.
 */
static inline void w_stvec(uint64 x) {
	asm volatile("csrw stvec, %0" : : "r"(x));
}
/**
 * r_scause
 * What it does: Reads the Supervisor Cause (scause) register.
 * Why it exists: When a trap occurs, we need to know WHY it happened (e.g. was it a timer interrupt, 
 * or a system call?). This register contains that reason code.
 */
static inline uint64 r_scause() {
	uint64 x;
	asm volatile("csrr %0, scause" : "=r"(x));
	return x;
}
/**
 * r_sepc
 * What it does: Reads the Supervisor Exception Program Counter (sepc) register.
 * Why it exists: When a trap occurs, the CPU saves the exact line of code (memory address) 
 * where the program was interrupted into this register, so we can return to it later.
 */
static inline uint64 r_sepc() {
	uint64 x;
	asm volatile("csrr %0, sepc" : "=r"(x));
	return x;
}
/**
 * w_sepc
 * What it does: Writes a value to the Supervisor Exception Program Counter (sepc) register.
 * Why it exists: Used to modify where a program will resume after a trap. For example, 
 * jumping PAST the 'ecall' instruction so it doesn't loop infinitely.
 */
static inline void w_sepc(uint64 x) {
	asm volatile("csrw sepc, %0" : : "r"(x));
}
/**
 * r_sstatus
 * What it does: Reads the Supervisor Status (sstatus) register.
 * Why it exists: Contains flags about the current state of the CPU, such as whether 
 * interrupts are globally enabled or disabled.
 */
static inline uint64 r_sstatus() {
	uint64 x;
	asm volatile("csrr %0, sstatus" : "=r"(x));
	return x;
}
/**
 * w_sstatus
 * What it does: Writes a value to the Supervisor Status (sstatus) register.
 * Why it exists: Used to turn interrupts on or off, or change the CPU's privilege mode.
 */
static inline void w_sstatus(uint64 x) {
	asm volatile("csrw sstatus, %0" : : "r"(x));
}
/**
 * w_sscratch
 * What it does: Writes a value to the Supervisor Scratch (sscratch) register.
 * Why it exists: A temporary holding space used by assembly trap handlers to save 
 * the trapframe pointer so it isn't lost during the very first steps of a trap.
 */
static inline void w_sscratch(uint64 x) {
	asm volatile("csrw sscratch, %0" : : "r"(x));
}
