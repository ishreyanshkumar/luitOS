#include "types.h"
#include "defs.h"
#include "mailbox.h"

/*
 * Lab 6: bounded blocking mailboxes.
 *
 * The syscall wrappers at the bottom of this file are supplied.  Complete
 * TODO regions M1--M5.  Optional helper functions may be added only inside
 * the LAB6-HELPERS markers.  Keep all editable-region markers intact.
 */

struct mailbox {
    struct spinlock lock;
    int data[MBOX_CAP];

    /* TODO-BEGIN M1: define all per-mailbox queue and wait-state fields. */
    /*
     * Everything below is protected by lock:
     *   head   - index of the oldest element (next to remove)
     *   tail   - index where the next element will be inserted
     *   count  - number of buffered elements, 0 <= count <= MBOX_CAP
     *   closed - permanent close flag (never cleared until reboot)
     *
     * rchan/wchan are never read or written; only their ADDRESSES are used
     * as two distinct, stable sleep channels:
     *   &rchan : "data may be available"  (receivers sleep here)
     *   &wchan : "space may be available" (senders sleep here)
     */
    int head;
    int tail;
    int count;
    int closed;
    char rchan;
    char wchan;
    /* TODO-END M1 */
};

static struct mailbox mboxes[NMAILBOX];

static int
valid_id(int id)
{
    return id >= 0 && id < NMAILBOX;
}

/* Optional helper functions may be added only between these two markers. */
/* LAB6-HELPERS-BEGIN */
/* LAB6-HELPERS-END */

void
mailboxinit(void)
{
    for (int i = 0; i < NMAILBOX; i++) {
        initlock(&mboxes[i].lock, "mailbox");

        /* TODO-BEGIN M2: initialize every mailbox field you added in M1. */
        for (int j = 0; j < MBOX_CAP; j++)
            mboxes[i].data[j] = 0;
        mboxes[i].head = 0;
        mboxes[i].tail = 0;
        mboxes[i].count = 0;
        mboxes[i].closed = 0;
        mboxes[i].rchan = 0;
        mboxes[i].wchan = 0;
        /* TODO-END M2 */
    }
}

int
mbox_send(int id, int value)
{
    if (!valid_id(id) || value < 0)
        return -1;

    /* TODO-BEGIN M3: implement blocking send with the mailbox lock. */
    struct mailbox *mb = &mboxes[id];

    acquire(&mb->lock);

    /* Wait while full, but only if waiting can still help (still open). */
    while (mb->count == MBOX_CAP && !mb->closed)
        sleep(&mb->wchan, &mb->lock);

    /* Terminal state: closed (before or while we slept) -> no insertion. */
    if (mb->closed) {
        release(&mb->lock);
        return -1;
    }

    /* Open and count < MBOX_CAP here, guaranteed by the lock. */
    mb->data[mb->tail] = value;
    mb->tail = (mb->tail + 1) % MBOX_CAP;
    mb->count++;

    /* Data now exists: wake receivers. */
    wakeup(&mb->rchan);

    release(&mb->lock);
    return 0;
    /* TODO-END M3 */
}

int
mbox_recv(int id)
{
    if (!valid_id(id))
        return -1;

    /* TODO-BEGIN M4: implement blocking receive with the mailbox lock. */
    struct mailbox *mb = &mboxes[id];
    int v;

    acquire(&mb->lock);

    /* Wait while empty, but only if waiting can still help (still open). */
    while (mb->count == 0 && !mb->closed)
        sleep(&mb->rchan, &mb->lock);

    /* Empty here implies closed: closed-and-drained -> end of stream. */
    if (mb->count == 0) {
        release(&mb->lock);
        return -1;
    }

    /* Non-empty (open or closed): drain before end-of-stream. */
    v = mb->data[mb->head];
    mb->head = (mb->head + 1) % MBOX_CAP;
    mb->count--;

    /* A slot is now free: wake senders. */
    wakeup(&mb->wchan);

    release(&mb->lock);
    return v;
    /* TODO-END M4 */
}

int
mbox_close(int id)
{
    if (!valid_id(id))
        return -1;

    /* TODO-BEGIN M5: close idempotently and wake every relevant waiter. */
    struct mailbox *mb = &mboxes[id];

    acquire(&mb->lock);

    mb->closed = 1;          /* idempotent; buffered data is untouched */
    wakeup(&mb->rchan);      /* empty+closed receivers must return -1  */
    wakeup(&mb->wchan);      /* full+closed senders must return -1     */

    release(&mb->lock);
    return 0;
    /* TODO-END M5 */
}

/*
 * Supplied syscall boundary.
 *
 * LUIT places user integer arguments in the saved trapframe registers.  Read
 * them as unsigned values first so a negative user argument is rejected by
 * the range checks below rather than silently wrapping into a valid ID/value.
 */
uint64
sys_mbox_send(void)
{
    struct proc *p = myproc();
    uint64 id = p->tf->a0;
    uint64 value = p->tf->a1;

    if (id >= NMAILBOX || value > 0x7fffffffULL)
        return (uint64)-1;

    return (uint64)mbox_send((int)id, (int)value);
}

uint64
sys_mbox_recv(void)
{
    struct proc *p = myproc();
    uint64 id = p->tf->a0;

    if (id >= NMAILBOX)
        return (uint64)-1;

    return (uint64)mbox_recv((int)id);
}

uint64
sys_mbox_close(void)
{
    struct proc *p = myproc();
    uint64 id = p->tf->a0;

    if (id >= NMAILBOX)
        return (uint64)-1;

    return (uint64)mbox_close((int)id);
}
