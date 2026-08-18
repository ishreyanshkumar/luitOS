/* L10/L11 - Sv39 VIRTUAL MEMORY.
 *
 * DESIGN DECISION (students must be able to defend this in viva):
 * We map the kernel into EVERY process address space, the way Linux does,
 * rather than keeping a separate kernel page table and switching satp on every
 * trap (which is what xv6 does, and why xv6 needs a trampoline page).
 *   - User memory lives LOW:  0 .. 0x8000_0000   -> top-level indices 0,1
 *   - Kernel RAM lives HIGH:  0x8000_0000 ..     -> top-level index 2,3
 *   - MMIO is aliased at      pa + 0x1_0000_0000  -> top-level index 4
 * Because they never collide, a user page table can simply borrow the kernel's
 * top-level entries (>= index 2). Kernel pages lack PTE_U, so user code still
 * cannot touch them - the MMU enforces that, not us.
 * Cost: user address space is capped at 2 GiB. We accept that, and say so.
 */
#include "types.h"
#include "defs.h"
#include "hal.h"

pagetable_t kernel_pagetable;
extern char etext[];

#define MMIO_OFFSET   0x100000000UL          /* MMIO alias base */
#define MMIO_VA(pa)   ((pa) + MMIO_OFFSET)

/* The ONE place that knows where MMIO lives in the virtual map. HAL backends
 * call this instead of hardcoding the offset (see §MMIO policy, hal/hal.h). */
uint64 mmio_alias(uint64 pa) { return MMIO_VA(pa); }
#define USER_TOP      0x80000000UL           /* user VAs must stay below this */
#define KERN_IDX_LO   2                      /* top-level indices >= this are kernel */

/* Walk the three levels. If alloc, create missing page-table pages. */
pte_t *walk(pagetable_t pt, uint64 va, int alloc)
{
    if (va >= MAXVA) panic("walk: va out of range");

    for (int level = 2; level > 0; level--) {
        pte_t *pte = &pt[PX(level, va)];
        if (*pte & PTE_V) {
            pt = (pagetable_t)PTE2PA(*pte);
        } else {
            if (!alloc) return 0;
            pt = (pagetable_t)palloc();
            if (!pt) return 0;
            memset(pt, 0, PGSIZE);
            /* An interior PTE has NO R/W/X bits - that is what makes it a
             * pointer to the next level rather than a leaf. */
            *pte = PA2PTE(pt) | PTE_V;
        }
    }
    return &pt[PX(0, va)];
}

uint64 walkaddr(pagetable_t pt, uint64 va)
{
    if (va >= MAXVA) return 0;
    pte_t *pte = walk(pt, va, 0);
    if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return 0;
    return PTE2PA(*pte);
}

int mappages(pagetable_t pt, uint64 va, uint64 size, uint64 pa, int perm)
{
    if (size == 0) panic("mappages: zero size");
    uint64 a    = PGROUNDDOWN(va);
    uint64 last = PGROUNDDOWN(va + size - 1);

    for (;;) {
        pte_t *pte = walk(pt, a, 1);
        if (!pte) return -1;
        if (*pte & PTE_V) panic("mappages: remap");
        *pte = PA2PTE(pa) | perm | PTE_V;
        if (a == last) break;
        a  += PGSIZE;
        pa += PGSIZE;
    }
    return 0;
}

static void kvmmap(uint64 va, uint64 pa, uint64 sz, int perm)
{
    if (mappages(kernel_pagetable, va, sz, pa, perm) != 0)
        panic("kvmmap");
}

void kvminit(void)
{
    kernel_pagetable = (pagetable_t)palloc();
    memset(kernel_pagetable, 0, PGSIZE);

    /* MMIO, at its high alias. Addresses come from the DEVICE TREE. */
    kvmmap(MMIO_VA(fdt.uart_base), fdt.uart_base, PGSIZE, PTE_R | PTE_W);
    if (fdt.plic_base)
        kvmmap(MMIO_VA(fdt.plic_base), fdt.plic_base, 0x400000, PTE_R | PTE_W);
    for (int i = 0; i < fdt.nvirtio; i++)
        kvmmap(MMIO_VA(fdt.virtio_base[i]), fdt.virtio_base[i], PGSIZE, PTE_R | PTE_W);

    /* Kernel text: read + EXECUTE, but NOT writable. W^X, actually enforced.
     * A hidden test checks that kernel text is not writable. */
    uint64 ktext = 0x80200000UL;
    kvmmap(ktext, ktext, (uint64)etext - ktext, PTE_R | PTE_X);

    /* Everything else in RAM: read/write, no execute. */
    uint64 mem_end = fdt.mem_base + fdt.mem_size;
    kvmmap((uint64)etext, (uint64)etext, mem_end - (uint64)etext, PTE_R | PTE_W);

    /* OpenSBI's region below our kernel - map RW so we never fault touching it. */
    if (fdt.mem_base < ktext)
        kvmmap(fdt.mem_base, fdt.mem_base, ktext - fdt.mem_base, PTE_R | PTE_W);
}

void kvminithart(void)
{
    sfence_vma();                                /* flush stale entries first  */
    w_satp(MAKE_SATP(kernel_pagetable));
    sfence_vma();                                /* ...and again after. If you
                                                  * skip this, you get a kernel
                                                  * that works until it doesn't. */
}

/* ---------- user page tables ---------- */

pagetable_t uvmcreate(void)
{
    pagetable_t pt = (pagetable_t)palloc();
    if (!pt) return 0;
    memset(pt, 0, PGSIZE);
    /* Borrow every kernel top-level entry. No PTE_U on any of them, so the
     * hardware refuses user access - we get isolation for free. */
    for (int i = KERN_IDX_LO; i < 512; i++)
        pt[i] = kernel_pagetable[i];
    return pt;
}

void uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free)
{
    for (uint64 a = va; a < va + npages * PGSIZE; a += PGSIZE) {
        pte_t *pte = walk(pt, a, 0);
        if (!pte || !(*pte & PTE_V)) continue;     /* lazily-allocated: fine */
        if (do_free) pfree((void *)PTE2PA(*pte));
        *pte = 0;
    }
}

/* Free ONLY the user half of the tree (indices 0..1). Kernel entries are
 * borrowed, not owned - freeing them would take down every other process. */
static void freewalk_user(pagetable_t pt, int level)
{
    int limit = (level == 2) ? KERN_IDX_LO : 512;
    for (int i = 0; i < limit; i++) {
        pte_t pte = pt[i];
        if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0) {
            freewalk_user((pagetable_t)PTE2PA(pte), level - 1);
            pt[i] = 0;
        }
    }
    pfree((void *)pt);
}

void uvmfree(pagetable_t pt, uint64 sz)
{
    if (sz > 0) uvmunmap(pt, 0, PGROUNDUP(sz) / PGSIZE, 1);
    freewalk_user(pt, 2);
}

/* fork(): duplicate the parent's user pages into the child, EAGERLY.
 * Every writable byte is copied whether the child will ever touch it or not.
 * Correct, simple - and the single biggest cost of fork(), which is exactly
 * why Lab 5 replaces this with copy-on-write. The page allocator's refcount
 * machinery (palloc_ref_inc/get) is already in place waiting for it. */
int uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    for (uint64 i = 0; i < sz; i += PGSIZE) {
        pte_t *pte = walk(old, i, 0);
        if (!pte || !(*pte & PTE_V)) continue;

        uint64 pa    = PTE2PA(*pte);
        uint64 flags = PTE_FLAGS(*pte);

        char *mem = palloc();
        if (!mem) { uvmunmap(new, 0, i / PGSIZE, 1); return -1; }
        memmove(mem, (void *)pa, PGSIZE);
        if (mappages(new, i, PGSIZE, (uint64)mem, flags) != 0) {
            pfree(mem);
            uvmunmap(new, 0, i / PGSIZE, 1);
            return -1;
        }
    }
    return 0;
}

/* ---------- crossing the user/kernel boundary ----------
 * NEVER dereference a user pointer directly. Always go through these: they
 * walk the user page table and check the mapping exists and is user-accessible.
 * A user process must not be able to make the kernel fault. This is graded. */

int copyout(pagetable_t pt, uint64 dstva, char *src, uint64 len)
{
    while (len > 0) {
        uint64 va0 = PGROUNDDOWN(dstva);
        if (va0 >= USER_TOP) return -1;

        pte_t *pte = walk(pt, va0, 0);
        if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return -1;

        if (!(*pte & PTE_W)) return -1;   /* read-only page: refuse.
             Lab 5 (copy-on-write) teaches this line to do something smarter. */
        uint64 pa0 = PTE2PA(*pte);
        uint64 n = PGSIZE - (dstva - va0);
        if (n > len) n = len;
        memmove((void *)(pa0 + (dstva - va0)), src, n);
        len -= n; src += n; dstva = va0 + PGSIZE;
    }
    return 0;
}

int copyin(pagetable_t pt, char *dst, uint64 srcva, uint64 len)
{
    while (len > 0) {
        uint64 va0 = PGROUNDDOWN(srcva);
        uint64 pa0 = walkaddr(pt, va0);
        if (pa0 == 0) return -1;
        uint64 n = PGSIZE - (srcva - va0);
        if (n > len) n = len;
        memmove(dst, (void *)(pa0 + (srcva - va0)), n);
        len -= n; dst += n; srcva = va0 + PGSIZE;
    }
    return 0;
}

int copyinstr(pagetable_t pt, char *dst, uint64 srcva, uint64 max)
{
    int got_null = 0;
    while (got_null == 0 && max > 0) {
        uint64 va0 = PGROUNDDOWN(srcva);
        uint64 pa0 = walkaddr(pt, va0);
        if (pa0 == 0) return -1;
        uint64 n = PGSIZE - (srcva - va0);
        if (n > max) n = max;
        char *p = (char *)(pa0 + (srcva - va0));
        while (n > 0) {
            *dst = *p;
            if (*p == '\0') { got_null = 1; break; }
            dst++; p++; n--; max--;
        }
        srcva = va0 + PGSIZE;
    }
    return got_null ? 0 : -1;
}

/* Debug aid you will use all semester, and in Viva #2. */
static void vmprint_lvl(pagetable_t pt, int level)
{
    for (int i = 0; i < 512; i++) {
        pte_t pte = pt[i];
        if (!(pte & PTE_V)) continue;
        if (level == 2 && i >= KERN_IDX_LO) continue;   /* skip borrowed kernel */
        for (int d = 2; d >= level; d--) printf(" ..");
        printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
        if ((pte & (PTE_R | PTE_W | PTE_X)) == 0 && level > 0)
            vmprint_lvl((pagetable_t)PTE2PA(pte), level - 1);
    }
}
void vmprint(pagetable_t pt)
{
    printf("page table %p (user half)\n", pt);
    vmprint_lvl(pt, 2);
}
