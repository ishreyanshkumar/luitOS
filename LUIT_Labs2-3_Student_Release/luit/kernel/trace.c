/* Lab 2: kernel tracing subsystem.  ==== STUDENT SKELETON ====
 *
 * Your task: build a per-hart ring-buffer tracer. The hot path (trace_record)
 * must record on the LOCAL hart with no global lock; overflow must be COUNTED
 * (never silently dropped); traceread must drain all harts; and fork must make
 * a child inherit its parent's filter.
 *
 * The interfaces below are fixed (syscall.c, proc.c and main.c already call
 * them). Fill in the bodies marked TODO. The stubs as shipped compile and boot
 * so you can practise with GDB immediately, but they record nothing until you
 * implement them. See docs/labs-v2/lab02.md for the full specification, and the
 * GDB practice guide for where each of these is called from.
 */
#include "types.h"
#include "defs.h"
#include "param.h"
#include "hal.h"
#include "trace.h"

/* A per-hart ring. One of these per CPU means the hot path takes only the
 * local ring's lock, so harts do not contend. */
struct trace_ring {
    struct spinlock lock;
    struct trace_event ev[NTRACE];
    uint32 head, count, dropped;
};
static struct trace_ring rings[NCPU];

/* Called once at boot (kernel/main.c). Initialise every ring's lock and counters. */
void trace_init(void)
{
    for (int i = 0; i < NCPU; i++) {
        initlock(&rings[i].lock, "trace");
        rings[i].head = rings[i].count = rings[i].dropped = 0;
    }
}

/* Called from syscall() right after each syscall is dispatched, with the
 * syscall number, its return value, and its first argument.
 *
 * TODO (Lab 2):
 *   1. Get the current process; if it has no trace_filter set, return.
 *   2. Honour the filter: bit 63 = "trace everything"; otherwise bit `num`
 *      selects syscall number `num`.
 *   3. Record into THIS hart's ring (use hal_hart_id()). If the ring is full,
 *      increment `dropped` instead of overwriting. Fill pid, hart, num, ret,
 *      arg0, and a timestamp from r_time().
 */
void trace_record(int num, long ret, uint64 arg0)
{
    (void)num; (void)ret; (void)arg0;
    /* TODO: implement per-hart recording with overflow accounting. */
}

/* Backing the tracectl() syscall. action is TRACE_ENABLE or TRACE_DISABLE.
 * TODO: set or clear the current process's trace_filter accordingly. */
int trace_ctl(int action, uint64 filter)
{
    (void)action; (void)filter;
    /* TODO: implement enable/disable of the per-process filter. */
    return -1;
}

/* Backing the traceread() syscall. Copy up to `max` events out to ubuf,
 * draining every hart's ring. TODO: drain each ring under its lock, copyout
 * each event, and surface the per-ring `dropped` count as an overflow record. */
int trace_read(uint64 ubuf, int max)
{
    (void)ubuf; (void)max;
    /* TODO: implement the cross-hart drain. */
    return 0;
}

/* Called from fork(). TODO: make the child inherit the parent's trace_filter. */
void trace_fork(struct proc *parent, struct proc *child)
{
    (void)parent; (void)child;
    /* TODO: copy the filter so a traced process's children are traced too. */
}
