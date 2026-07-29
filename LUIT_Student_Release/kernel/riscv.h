#ifndef LUIT_RISCV_H
#define LUIT_RISCV_H
#include "types.h"

static inline uint64 r_tp(void){ uint64 x; asm volatile("mv %0, tp":"=r"(x)); return x; }
static inline uint64 r_sstatus(void){ uint64 x; asm volatile("csrr %0, sstatus":"=r"(x)); return x; }
static inline void   w_sstatus(uint64 x){ asm volatile("csrw sstatus, %0"::"r"(x)); }
static inline uint64 r_sie(void){ uint64 x; asm volatile("csrr %0, sie":"=r"(x)); return x; }
static inline void   w_sie(uint64 x){ asm volatile("csrw sie, %0"::"r"(x)); }
static inline void   w_stvec(uint64 x){ asm volatile("csrw stvec, %0"::"r"(x)); }
static inline uint64 r_scause(void){ uint64 x; asm volatile("csrr %0, scause":"=r"(x)); return x; }
static inline uint64 r_sepc(void){ uint64 x; asm volatile("csrr %0, sepc":"=r"(x)); return x; }
static inline void   w_sepc(uint64 x){ asm volatile("csrw sepc, %0"::"r"(x)); }
static inline uint64 r_stval(void){ uint64 x; asm volatile("csrr %0, stval":"=r"(x)); return x; }
static inline void   w_sscratch(uint64 x){ asm volatile("csrw sscratch, %0"::"r"(x)); }
static inline uint64 r_satp(void){ uint64 x; asm volatile("csrr %0, satp":"=r"(x)); return x; }
static inline void   w_satp(uint64 x){ asm volatile("csrw satp, %0"::"r"(x)); }
static inline uint64 r_time(void){ uint64 x; asm volatile("rdtime %0":"=r"(x)); return x; }
static inline void   sfence_vma(void){ asm volatile("sfence.vma zero, zero"); }

#define SSTATUS_SIE  (1L << 1)   /* S-mode interrupt enable */
#define SSTATUS_SPIE (1L << 5)   /* prior interrupt enable   */
#define SSTATUS_SPP  (1L << 8)   /* previous privilege: 1=S, 0=U */
#define SIE_SSIE (1L << 1)
#define SIE_STIE (1L << 5)       /* timer  */
#define SIE_SEIE (1L << 9)       /* external */

static inline void intr_on(void){ w_sstatus(r_sstatus() | SSTATUS_SIE); }
static inline void intr_off(void){ w_sstatus(r_sstatus() & ~SSTATUS_SIE); }
static inline int  intr_get(void){ return (r_sstatus() & SSTATUS_SIE) != 0; }

/* Sv39 */
#define PGSIZE 4096
#define PGSHIFT 12
#define PGROUNDUP(a)   (((a) + PGSIZE - 1) & ~(PGSIZE - 1))
#define PGROUNDDOWN(a) ((a) & ~(PGSIZE - 1))

#define PTE_V (1L << 0)
#define PTE_R (1L << 1)
#define PTE_W (1L << 2)
#define PTE_X (1L << 3)
#define PTE_U (1L << 4)
#define PTE_A (1L << 6)
#define PTE_D (1L << 7)
/* Implementation note. */
#define PTE_COW (1L << 8)  /* Implementation note. */


#define PA2PTE(pa) ((((uint64)(pa)) >> 12) << 10)
#define PTE2PA(pte) (((pte) >> 10) << 12)
#define PTE_FLAGS(pte) ((pte) & 0x3FF)
#define PX(level, va) ((((uint64)(va)) >> (PGSHIFT + 9 * (level))) & 0x1FF)
#define MAXVA (1L << 38)
#define SATP_SV39 (8L << 60)
#define MAKE_SATP(pt) (SATP_SV39 | (((uint64)(pt)) >> 12))

typedef uint64 pte_t;
typedef uint64 *pagetable_t;

#endif
