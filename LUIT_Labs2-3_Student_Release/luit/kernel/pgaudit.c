/* Lab 5: COW auditing and invariant checking. */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "riscv.h"
struct pgref { int refcount; int cow; int writable; };
int pgrefstat(pagetable_t pt, uint64 va, struct pgref *out) {
    pte_t *pte = walk(pt, PGROUNDDOWN(va), 0);
    if (!pte || !(*pte & PTE_V) || !(*pte & PTE_U)) return -1;
    out->refcount = palloc_ref_get((void *)PTE2PA(*pte));
    out->cow = (*pte & PTE_COW) ? 1 : 0;
    out->writable = (*pte & PTE_W) ? 1 : 0;
    return 0;
}
int pgaudit(pagetable_t pt, uint64 sz) {
    for (uint64 a = 0; a < sz; a += PGSIZE) {
        pte_t *pte = walk(pt, a, 0);
        if (!pte || !(*pte & PTE_V)) continue;
        if (!(*pte & PTE_U)) continue;
        uint64 pa = PTE2PA(*pte);
        int rc = palloc_ref_get((void *)pa);
        if (rc < 1) return 1;
        if ((*pte & PTE_COW) && (*pte & PTE_W)) return 2;
        if (rc > 1 && (*pte & PTE_W) && !(*pte & PTE_COW)) return 3;
    }
    return 0;
}
