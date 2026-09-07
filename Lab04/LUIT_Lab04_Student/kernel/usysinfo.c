/* Lab 3: versioned shared kernel/user information page.
 *
 * The mapping/lifetime code in this file is PROVIDED. It is the same
 * read-only mapping that you inspected in the non-graded GDB practice.
 * Your graded kernel task is the publication protocol in usysinfo_update().
 */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "hal.h"
#include "usysinfo.h"

extern uint64 ticks;

/* PROVIDED: one physical page per process, user-readable but not user-writable. */
int
usysinfo_setup(struct proc *p)
{
    char *mem = palloc();
    if (mem == 0)
        return -1;
    memset(mem, 0, PGSIZE);

    struct usysinfo *u = (struct usysinfo *)mem;
    u->version = USYSINFO_VERSION;
    u->seq = 0;

    if (mappages(p->pagetable, USYSINFO_VA, PGSIZE, (uint64)mem,
                 PTE_R | PTE_U) != 0) {
        pfree(mem);
        return -1;
    }
    p->usysinfo = u;
    return 0;
}

/* PROVIDED: USYSINFO_VA lies above p->sz, so ordinary uvmfree() will not
 * free the backing leaf page. Remove it explicitly before freeing the tree. */
void
usysinfo_free(struct proc *p)
{
    if (p->usysinfo) {
        if (p->pagetable)
            uvmunmap(p->pagetable, USYSINFO_VA, 1, 1);
        p->usysinfo = 0;
    }
}

/* PROVIDED: exec() builds a fresh process page table. Re-map the same
 * per-process information page into the new address space before commit. */
int
usysinfo_remap(struct proc *p, pagetable_t newpt)
{
    if (p->usysinfo == 0)
        return 0;
    if (mappages(newpt, USYSINFO_VA, PGSIZE, (uint64)p->usysinfo,
                 PTE_R | PTE_U) != 0)
        return -1;
    return 0;
}

void
usysinfo_update(struct proc *p)
{
    if (p->usysinfo == 0)
        return;

    push_off();
    struct usysinfo *u = p->usysinfo;

    u->seq++;                         /* odd: publication in progress */
    __sync_synchronize();

    u->pid           = p->pid;
    u->hart          = hal_hart_id();
    u->ticks         = ticks;
    u->syscall_count = p->syscall_count;
    u->ctxsw_count   = p->ctxsw_count;
    u->state_gen     = p->state_gen;

    __sync_synchronize();
    u->seq++;                         /* even: stable snapshot */
    pop_off();
}
