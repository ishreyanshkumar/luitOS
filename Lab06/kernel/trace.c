/* Lab 2: kernel tracing subsystem. Per-hart ring buffers; the hot path records
 * on the local hart without global contention. Overflow is counted, never
 * silently dropped. traceread drains all harts under each ring's lock. Fork
 * inheritance follows a process tree. */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "hal.h"
#include "trace.h"

struct trace_ring {
    struct spinlock lock;
    struct trace_event ev[NTRACE];
    uint32 head, count, dropped;
};
static struct trace_ring rings[NCPU];

void trace_init(void)
{
    for (int i = 0; i < NCPU; i++) {
        initlock(&rings[i].lock, "trace");
        rings[i].head = rings[i].count = rings[i].dropped = 0;
    }
}

void trace_record(int num, long ret, uint64 arg0)
{
    struct proc *p = myproc();
    if (p == 0 || p->trace_filter == 0) return;
    if (!(p->trace_filter & (1UL << 63)) &&
        (num >= 63 || !(p->trace_filter & (1UL << num)))) return;

    int h = hal_hart_id();
    struct trace_ring *r = &rings[h];
    acquire(&r->lock);
    if (r->count == NTRACE) {
        r->dropped++;
    } else {
        struct trace_event *e = &r->ev[r->head];
        e->pid = p->pid; e->hart = h; e->num = num;
        e->ret = ret; e->ts = r_time(); e->arg0 = arg0;
        r->head = (r->head + 1) % NTRACE;
        r->count++;
    }
    release(&r->lock);
}

int trace_ctl(int action, uint64 filter)
{
    struct proc *p = myproc();
    if (action == TRACE_DISABLE) { p->trace_filter = 0; return 0; }
    if (action == TRACE_ENABLE) {
        p->trace_filter = filter ? filter : (1UL << 63);
        return 0;
    }
    return -1;
}

int trace_read(uint64 ubuf, int max)
{
    if (max <= 0) return -1;
    struct proc *p = myproc();
    int total = 0;
    for (int h = 0; h < NCPU && total < max; h++) {
        struct trace_ring *r = &rings[h];
        acquire(&r->lock);
        uint32 tail = (r->head + NTRACE - r->count) % NTRACE;
        while (r->count > 0 && total < max) {
            struct trace_event e = r->ev[tail];
            release(&r->lock);
            if (copyout(p->pagetable, ubuf + total * sizeof(e), (char *)&e, sizeof(e)) < 0)
                return total > 0 ? total : -1;
            acquire(&r->lock);
            tail = (tail + 1) % NTRACE;
            r->count--; total++;
        }
        if (r->dropped > 0 && total < max) {
            struct trace_event d;
            d.pid = -1; d.hart = h; d.num = -1; d.ret = 0; d.ts = 0; d.arg0 = r->dropped;
            r->dropped = 0;
            release(&r->lock);
            if (copyout(p->pagetable, ubuf + total * sizeof(d), (char *)&d, sizeof(d)) < 0)
                return total > 0 ? total : -1;
            total++;
            continue;
        }
        release(&r->lock);
    }
    return total;
}

void trace_fork(struct proc *parent, struct proc *child)
{
    child->trace_filter = parent->trace_filter;
}
