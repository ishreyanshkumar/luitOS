/* SLEEP LOCKS - locks you may hold across disk I/O.
 *
 * A spinlock spins with interrupts off: correct for microsecond critical
 * sections, catastrophic around a disk request that takes milliseconds and
 * COMPLETES VIA AN INTERRUPT you just disabled. A sleeplock instead puts the
 * would-be owner to SLEEP, so the hart runs something else.
 *
 * INVARIANTS
 *  - lk->lk (a spinlock) guards lk->locked and lk->pid, nothing else.
 *  - You may sleep while HOLDING a sleeplock; you may never sleep while
 *    holding a spinlock (sched() panics: "holding another lock too").
 *  - Never acquire a sleeplock from interrupt context: interrupts have no
 *    process to put to sleep.
 */
#include "types.h"
#include "defs.h"

void initsleeplock(struct sleeplock *lk, const char *name)
{
    initlock(&lk->lk, "sleep lock");
    lk->name = name;
    lk->locked = 0;
    lk->pid = 0;
}

void acquiresleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    while (lk->locked)
        sleep(lk, &lk->lk);       /* releases lk->lk while asleep */
    lk->locked = 1;
    lk->pid = myproc()->pid;
    release(&lk->lk);
}

void releasesleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    lk->locked = 0;
    lk->pid = 0;
    wakeup(lk);
    release(&lk->lk);
}

int holdingsleep(struct sleeplock *lk)
{
    acquire(&lk->lk);
    int r = lk->locked && (lk->pid == myproc()->pid);
    release(&lk->lk);
    return r;
}
