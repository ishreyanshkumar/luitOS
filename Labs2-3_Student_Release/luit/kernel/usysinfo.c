/* Lab 3: versioned shared info page.  ==== STUDENT SKELETON ====
 *
 * Your task: implement the kernel-side SEQLOCK WRITER so a user process can read
 * a shared page at USYSINFO_VA with no system call and never see a torn (half-
 * updated) snapshot.
 *
 * The page is mapped READ-ONLY into user space (PTE_R | PTE_U, no PTE_W) — the
 * mapping code below is provided. What you must write is usysinfo_update(): the
 * seqlock protocol that lets a lock-free user reader detect an in-progress write.
 *
 * See docs/labs-v2/lab03.md for the full specification and the GDB practice
 * guide (Section 7) for how to watch the seqlock step in the debugger.
 */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "hal.h"
#include "usysinfo.h"

extern uint64 ticks;

/* ---- The mapping infrastructure is provided (this is plumbing, not the lab's
 * core idea). Do not change the permissions: the page MUST stay read-only in
 * user space, or the whole safety argument collapses. ---- */

int usysinfo_setup(struct proc *p)
{
    char *mem = palloc();
    if (mem == 0) return -1;
    memset(mem, 0, PGSIZE);
    struct usysinfo *u = (struct usysinfo *)mem;
    u->version = USYSINFO_VERSION; u->seq = 0;
    if (mappages(p->pagetable, USYSINFO_VA, PGSIZE, (uint64)mem, PTE_R | PTE_U) != 0) {
        pfree(mem); return -1;
    }
    p->usysinfo = u;
    return 0;
}

/* uvmfree only frees [0,sz); the info page is above sz, so free it explicitly
 * or one page leaks per process (caught by the baseline leak test). */
void usysinfo_free(struct proc *p)
{
    if (p->usysinfo) {
        if (p->pagetable) uvmunmap(p->pagetable, USYSINFO_VA, 1, 1);
        p->usysinfo = 0;
    }
}

/* exec builds a fresh page table; re-map the existing info page into it. */
int usysinfo_remap(struct proc *p, pagetable_t newpt)
{
    if (p->usysinfo == 0) return 0;
    if (mappages(newpt, USYSINFO_VA, PGSIZE, (uint64)p->usysinfo, PTE_R | PTE_U) != 0)
        return -1;
    return 0;
}

/* ---- THE LAB 3 CORE: the seqlock writer. ----
 *
 * Called from syscall() and from the scheduler whenever this process's info
 * should be refreshed. A concurrent user reader will: read seq; if odd, retry;
 * read the fields; re-read seq; if it changed, retry.
 *
 * TODO (Lab 3):
 *   1. Bump seq to an ODD value to signal "update in progress".
 *   2. A memory barrier (__sync_synchronize) so the bump is visible BEFORE the
 *      field writes.
 *   3. Write the fields: pid, ppid, hart, ticks, syscall_count, ctxsw_count,
 *      state_gen.
 *   4. A memory barrier so the field writes land BEFORE the final bump.
 *   5. Bump seq to an EVEN value to signal "snapshot stable".
 *
 * Getting the two barriers right is the whole point — without them the reader
 * can observe a half-written page. The torn-snapshot test (usitest, 20000 reads)
 * is what proves you got it right.
 */
void usysinfo_update(struct proc *p)
{
    struct usysinfo *u = p->usysinfo;
    if (u == 0) return;
    /* TODO: implement the seqlock writer (odd -> barrier -> fields -> barrier -> even). */
    (void)ticks;
}
