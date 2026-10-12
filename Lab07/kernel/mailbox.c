#include "types.h"
#include "defs.h"
#include "mailbox.h"

/*
 * Completed Lab 6 dependency: bounded blocking mailboxes.
 * This implementation is supplied as part of the Lab 7 checkpoint.
 */

struct mailbox {
    struct spinlock lock;
    int data[MBOX_CAP];

    /* Completed Lab 6 state. */
    int head;
    int tail;
    int count;
    int closed;
    char can_read;
    char can_write;
};

static struct mailbox mboxes[NMAILBOX];

static int
valid_id(int id)
{
    return id >= 0 && id < NMAILBOX;
}

void
mailboxinit(void)
{
    for (int i = 0; i < NMAILBOX; i++) {
        initlock(&mboxes[i].lock, "mailbox");

        mboxes[i].head = 0;
        mboxes[i].tail = 0;
        mboxes[i].count = 0;
        mboxes[i].closed = 0;
        mboxes[i].can_read = 0;
        mboxes[i].can_write = 0;
    }
}

int
mbox_send(int id, int value)
{
    if (!valid_id(id) || value < 0)
        return -1;

    struct mailbox *mb = &mboxes[id];
    acquire(&mb->lock);

    while (mb->count == MBOX_CAP && !mb->closed)
        sleep(&mb->can_write, &mb->lock);

    if (mb->closed) {
        release(&mb->lock);
        return -1;
    }

    mb->data[mb->tail] = value;
    mb->tail = (mb->tail + 1) % MBOX_CAP;
    mb->count++;
    wakeup(&mb->can_read);
    release(&mb->lock);
    return 0;
}

int
mbox_recv(int id)
{
    if (!valid_id(id))
        return -1;

    struct mailbox *mb = &mboxes[id];
    acquire(&mb->lock);

    while (mb->count == 0 && !mb->closed)
        sleep(&mb->can_read, &mb->lock);

    if (mb->count == 0 && mb->closed) {
        release(&mb->lock);
        return -1;
    }

    int value = mb->data[mb->head];
    mb->head = (mb->head + 1) % MBOX_CAP;
    mb->count--;
    wakeup(&mb->can_write);
    release(&mb->lock);
    return value;
}

int
mbox_close(int id)
{
    if (!valid_id(id))
        return -1;

    struct mailbox *mb = &mboxes[id];
    acquire(&mb->lock);
    mb->closed = 1;
    wakeup(&mb->can_read);
    wakeup(&mb->can_write);
    release(&mb->lock);
    return 0;
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
