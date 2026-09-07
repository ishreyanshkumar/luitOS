/* Implementation note. */









#include "types.h"
#include "defs.h"
#include "hal.h"

void initlock(struct spinlock *lk, const char *name)
{
    lk->name = name; lk->locked = 0; lk->cpu = -1;
}

void acquire(struct spinlock *lk)
{
    push_off();
    if (holding(lk)) panic("acquire: already holding this lock");

    /* amoswap.w.aq: atomically swap 1 in; loop until we see the old value 0. */
    while (__sync_lock_test_and_set(&lk->locked, 1) != 0)
        ;
    __sync_synchronize();          /* fence: nothing below moves above this */
    lk->cpu = hal_hart_id();
}

void release(struct spinlock *lk)
{
    if (!holding(lk)) panic("release: not holding this lock");
    lk->cpu = -1;
    __sync_synchronize();          /* fence: nothing above moves below this */
    __sync_lock_release(&lk->locked);
    pop_off();
}

int holding(struct spinlock *lk)
{
    return lk->locked && lk->cpu == hal_hart_id();
}

void push_off(void)
{
    int old = intr_get();
    intr_off();
    struct cpu *c = mycpu();
    if (c->noff == 0) c->intena = old;   /* remember the ORIGINAL state */
    c->noff++;
}

void pop_off(void)
{
    struct cpu *c = mycpu();
    if (intr_get()) panic("pop_off: interrupts already on");
    if (c->noff < 1) panic("pop_off: unbalanced");
    c->noff--;
    if (c->noff == 0 && c->intena) intr_on();
}
