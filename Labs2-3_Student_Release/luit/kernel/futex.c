/* Lab 6: futex. The kernel's minimal blocking primitive.
 *
 * futex_wait(addr, expected): atomically - if the user word at addr still
 *   equals `expected`, sleep until woken; else return at once. The atomicity of
 *   the compare-and-sleep against a concurrent futex_wake is the lost-wakeup
 *   problem, solved exactly as the book's sleep/wakeup: hold the futex bucket
 *   lock across BOTH the compare and the sleep, so a waker (which takes the same
 *   lock) cannot slip between.
 *
 * Wait queues are keyed by user virtual address hashed into buckets; sleep()
 * uses the address itself as the channel. */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "futex.h"

#define NBUCKET 32
static struct spinlock buckets[NBUCKET];

void futex_init(void)
{
    for (int i = 0; i < NBUCKET; i++)
        initlock(&buckets[i], "futex");
}

static struct spinlock *bucket_for(uint64 uaddr)
{
    return &buckets[(uaddr >> 3) % NBUCKET];
}

int futex_wait(uint64 uaddr, uint64 expected)
{
    if (uaddr & 7) return -1;                  /* must be 8-byte aligned */
    struct proc *p = myproc();
    struct spinlock *b = bucket_for(uaddr);

    acquire(b);
    uint64 val;
    if (copyin(p->pagetable, (char *)&val, uaddr, sizeof(val)) < 0) {
        release(b); return -1;                 /* bad/unmapped address */
    }
    if (val != expected) { release(b); return 0; }   /* changed: don't sleep */

    /* sleep releases b and re-acquires p->lock atomically; a waker holding b
     * cannot have run its wakeup between our compare and here. */
    sleep((void *)uaddr, b);
    release(b);
    return 0;
}

int futex_wake(uint64 uaddr, int n)
{
    if (uaddr & 7) return -1;
    struct spinlock *b = bucket_for(uaddr);
    acquire(b);
    (void)n;                                   /* wakeup wakes all; re-check in user space */
    wakeup((void *)uaddr);
    release(b);
    return 0;
}
