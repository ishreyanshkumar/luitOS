/* Lab 4: user-level event delivery (timer alarms with alt-stack + masking).
 *
 * On each timer tick alarm_tick() counts down; when the interval elapses and no
 * handler is already running (masking), it saves the FULL user trapframe, points
 * epc at the handler and sp at the alt stack (if set), and returns to user mode
 * -> the handler runs. sigreturn restores the saved trapframe exactly, so the
 * interrupted code resumes with every register intact. */
#include "types.h"
#include "defs.h"
#include "param.h"

/* Called from usertrap on a timer interrupt. Returns 1 if it set up a delivery
 * (so the caller should NOT also yield into the handler path incorrectly). */
int alarm_tick(void)
{
    struct proc *p = myproc();
    if (p->alarm_interval == 0) return 0;      /* disabled */
    if (p->in_handler) return 0;               /* masked: don't nest */

    if (++p->alarm_ticks < (int)p->alarm_interval) return 0;
    p->alarm_ticks = 0;

    /* validate the handler address is a mapped user page */
    if (walkaddr(p->pagetable, PGROUNDDOWN(p->alarm_handler)) == 0)
        return 0;                              /* bad handler: skip (don't kill) */

    /* save the full trapframe so sigreturn can restore it exactly */
    if (p->alarm_saved == 0) {
        p->alarm_saved = (struct trapframe *)palloc();
        if (p->alarm_saved == 0) return 0;
    }
    *(p->alarm_saved) = *(p->tf);

    p->in_handler = 1;
    p->tf->epc = p->alarm_handler;             /* jump to handler */
    if (p->alarm_altstack)
        p->tf->sp = p->alarm_altstack;         /* run on the alt stack */
    return 1;
}
