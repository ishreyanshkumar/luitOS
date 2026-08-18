/* SYSTEM-CALL DISPATCH + process-related calls. File-related calls: sysfile.c.
 * ABI (docs/ABI.md, version 1): number in a7; args in a0..a5; result in a0;
 * negative = error. The dispatch table and SYS_* numbers are GENERATED from
 * kernel/syscall.tbl - one source of truth for kernel and user stubs alike.
 *
 * GOLDEN RULE, graded by a hidden adversarial test: the kernel must NEVER
 * dereference a user pointer directly. Everything goes through copyin/copyout.
 * A user process that passes a kernel address, a null, or an unmapped page
 * must get -1 back - not take the kernel down with it.
 */
#include "types.h"
#include "defs.h"
#include "futex.h"
#include "buf.h"
#include "fs.h"
#include "pstat.h"

/* fetch the n'th syscall argument (raw register) */
static uint64 argraw(int n)
{
    struct trapframe *tf = myproc()->tf;
    switch (n) {
    case 0: return tf->a0;
    case 1: return tf->a1;
    case 2: return tf->a2;
    case 3: return tf->a3;
    case 4: return tf->a4;
    case 5: return tf->a5;
    }
    panic("argraw: bad arg index");
}

int argint(int n, int *ip)     { *ip = (int)argraw(n); return 0; }
int argaddr(int n, uint64 *ap) { *ap = argraw(n); return 0; }

int fetchstr(uint64 addr, char *buf, int max)
{
    struct proc *p = myproc();
    if (copyinstr(p->pagetable, buf, addr, max) < 0) return -1;
    return strlen(buf);
}

int argstr(int n, char *buf, int max)
{
    uint64 addr;
    argaddr(n, &addr);
    return fetchstr(addr, buf, max);
}

/* ---- process-related system calls ---- */

uint64 sys_exit(void)
{
    int n; argint(0, &n);
    exit(n);
    return 0;
}

uint64 sys_getpid(void) { return myproc()->pid; }

uint64 sys_fork(void)   { return fork(); }

uint64 sys_wait(void)
{
    uint64 p; argaddr(0, &p);
    return wait(p);
}

uint64 sys_sbrk(void)
{
    int n; argint(0, &n);
    uint64 addr = myproc()->sz;
    if (growproc(n) < 0) return -1;
    return addr;
}

uint64 sys_sleep(void)
{
    int n; argint(0, &n);
    acquire(&tickslock);
    uint64 t0 = ticks;
    while (ticks - t0 < (uint64)n) {
        if (myproc()->killed) { release(&tickslock); return -1; }
        sleep(&ticks, &tickslock);
    }
    release(&tickslock);
    return 0;
}

uint64 sys_kill(void)
{
    int pid; argint(0, &pid);
    return kill(pid);
}

uint64 sys_uptime(void)
{
    acquire(&tickslock);
    uint64 t = ticks;
    release(&tickslock);
    return t;
}

/* Luit extras: test hooks and observability (used by meminfo and ps). */
uint64 sys_freepages(void) { return palloc_free_count(); }

uint64 sys_procstat(void)
{
    uint64 uaddr;
    int max;
    argaddr(0, &uaddr);
    argint(1, &max);
    if (max <= 0) return -1;
    if (max > NPROC) max = NPROC;
    return procstat(uaddr, max);
}

/* Lab 2: tracing syscalls. */
uint64 sys_tracectl(void) { int a; uint64 f; argint(0,&a); argaddr(1,&f); return trace_ctl(a,f); }
uint64 sys_traceread(void){ uint64 b; int m; argaddr(0,&b); argint(1,&m); return trace_read(b,m); }

/* Lab 5: COW audit syscalls. */
struct pgref { int refcount; int cow; int writable; };
uint64 sys_pgrefstat(void)
{
    uint64 va, out;
    argaddr(0, &va);
    argaddr(1, &out);
    struct proc *p = myproc();
    struct pgref r;
    if (pgrefstat(p->pagetable, va, &r) < 0)
        return -1;
    if (copyout(p->pagetable, out, (char *)&r, sizeof(r)) < 0)
        return -1;
    return 0;
}
uint64 sys_pgaudit(void){ struct proc *p=myproc(); return pgaudit(p->pagetable,p->sz); }

/* Lab 6: threads and futexes. */
uint64 sys_clone(void)
{
    uint64 fn, arg, stack;
    argaddr(0, &fn);
    argaddr(1, &arg);
    argaddr(2, &stack);
    return clone(fn, arg, stack);
}
uint64 sys_gettid(void) { return myproc()->pid; }
uint64 sys_futex(void)
{
    uint64 uaddr, val;
    int op, n;
    argaddr(0, &uaddr);
    argint(1, &op);
    argaddr(2, &val);
    argint(3, &n);
    if (op == FUTEX_WAIT) return futex_wait(uaddr, val);
    if (op == FUTEX_WAKE) return futex_wake(uaddr, n);
    return -1;
}

/* Lab 4: user-level event delivery. */
uint64 sys_sigalarm(void)
{
    int interval;
    uint64 handler;
    argint(0, &interval);
    argaddr(1, &handler);
    struct proc *p = myproc();
    p->alarm_interval = interval;
    p->alarm_handler = handler;
    p->alarm_ticks = 0;
    return 0;
}
uint64 sys_sigreturn(void)
{
    struct proc *p = myproc();
    if (p->alarm_saved == 0 || !p->in_handler) return -1;
    *(p->tf) = *(p->alarm_saved);           /* full restore */
    p->in_handler = 0;
    return p->tf->a0;                        /* preserve a0 */
}
uint64 sys_event_stack(void)
{
    uint64 sp;
    int size;
    argaddr(0, &sp);
    argint(1, &size);
    struct proc *p = myproc();
    if (sp && walkaddr(p->pagetable, PGROUNDDOWN(sp)) == 0) return -1;
    p->alarm_altstack = sp ? (sp + size) : 0;   /* top of the alt stack */
    return 0;
}

/* Lab 8: allocator instrumentation syscalls. */
struct allocstat { uint64 acquires[8]; uint64 allocs[8]; uint64 frees[8]; int nfree; int total; };
uint64 sys_alloc_stats(void)
{
    uint64 out;
    argaddr(0, &out);
    struct allocstat st;
    alloc_stats(&st);
    if (copyout(myproc()->pagetable, out, (char *)&st, sizeof(st)) < 0) return -1;
    return 0;
}
uint64 sys_alloc_audit(void) { return alloc_audit(); }

/* Lab 10: mmap syscalls. */
uint64 sys_mmap(void)
{
    uint64 addr, len, off;
    int prot, flags, fd;
    argaddr(0, &addr);
    argaddr(1, &len);
    argint(2, &prot);
    argint(3, &flags);
    argint(4, &fd);
    argaddr(5, &off);
    return mmap(addr, len, prot, flags, fd, off);
}
uint64 sys_munmap(void)
{
    uint64 addr, len;
    argaddr(0, &addr);
    argaddr(1, &len);
    return munmap(addr, len);
}

/* Lab 11: journal self-test. Runs a logged transaction over a few scratch
 * blocks in the data region, forces a header write (commit), simulates a crash
 * by discarding the in-memory state, then recovers and verifies the blocks. */
extern struct superblock sb;
uint64 sys_logtest(void)
{
    /* pick 3 scratch blocks near the end of the data region */
    int b0 = sb.datastart + sb.ndata - 8;
    begin_op();
    for (int i = 0; i < 3; i++) {
        struct buf *bp = bread(1, b0 + i);
        for (int j = 0; j < BSIZE; j++) bp->data[j] = (uint8)(0xA0 + i);
        log_write(bp);
        brelse(bp);
    }
    end_op();                      /* commits + installs */

    /* verify the blocks reached their homes */
    int ok = 1;
    for (int i = 0; i < 3; i++) {
        struct buf *bp = bread(1, b0 + i);
        for (int j = 0; j < BSIZE; j++)
            if (bp->data[j] != (uint8)(0xA0 + i)) ok = 0;
        brelse(bp);
    }
    return ok ? 0 : -1;
}

/* Lab 11: crash injection. Writes a transaction to the log and the commit
 * header, then STOPS - as if the machine lost power right after the commit
 * point, before installing to home blocks. Returns the base block so a test can
 * verify recovery replays it after reboot. The home blocks are left with their
 * OLD contents; only recovery on next mount should install the new ones. */
uint64 sys_logcrash(void)
{
    int b0 = sb.datastart + sb.ndata - 8;
    /* zero the home blocks first so we can tell recovery apart from a no-op */
    for (int i = 0; i < 3; i++) {
        struct buf *bp = bread(1, b0 + i);
        memset(bp->data, 0, BSIZE);
        bwrite(bp);
        brelse(bp);
    }
    /* now run a transaction but crash before install */
    begin_op();
    for (int i = 0; i < 3; i++) {
        struct buf *bp = bread(1, b0 + i);
        for (int j = 0; j < BSIZE; j++) bp->data[j] = (uint8)(0xC0 + i);
        log_write(bp);
        brelse(bp);
    }
    log_commit_only();          /* write log + header, then STOP (no install) */
    return b0;
}

/* Verify the home blocks hold the recovered pattern (called after reboot). */
uint64 sys_logverify(void)
{
    int b0 = sb.datastart + sb.ndata - 8;
    int ok = 1;
    for (int i = 0; i < 3; i++) {
        struct buf *bp = bread(1, b0 + i);
        for (int j = 0; j < BSIZE; j++)
            if (bp->data[j] != (uint8)(0xC0 + i)) ok = 0;
        brelse(bp);
    }
    return ok ? 0 : -1;
}

/* Lab 9: filesystem consistency check. */
uint64 sys_fsck(void) { return fsck(1); }

/* ---- dispatch ---- */

#include "syscalltab.h"     /* GENERATED: syscalls[] and syscall_names[] */

/* Lab 1: fdstat - report metadata for one fd of a target process. */
uint64 sys_fdstat(void)
{
    int pid, fd;
    uint64 out;
    argint(0, &pid);
    argint(1, &fd);
    argaddr(2, &out);
    if (fd < 0 || fd >= NOFILE) return -1;
    struct fdinfo fi;
    int found = fdstat_lookup(pid, fd, &fi);
    if (found < 0) return -1;
    if (copyout(myproc()->pagetable, out, (char *)&fi, sizeof(fi)) < 0) return -1;
    return 0;
}

/* Lab 1: abimeta - copy out (num,name) rows from the generated syscall table. */
struct abinfo { int num; char name[16]; };
uint64 sys_abimeta(void)
{
    uint64 buf;
    int max;
    argaddr(0, &buf);
    argint(1, &max);
    if (max <= 0) return -1;
    int n = 0;
    int nsys = sizeof(syscalls)/sizeof(syscalls[0]);
    for (int i = 1; i < nsys && n < max; i++) {
        if (!syscalls[i]) continue;
        struct abinfo a;
        a.num = i;
        const char *nm = syscall_name(i);
        int j = 0;
        for (; nm[j] && j < 15; j++) a.name[j] = nm[j];
        a.name[j] = 0;
        if (copyout(myproc()->pagetable, buf + n * sizeof(a), (char *)&a, sizeof(a)) < 0)
            return -1;
        n++;
    }
    return n;
}

void syscall(void)
{
    struct proc *p = myproc();
    uint64 num = p->tf->a7;

    /* Validate the number BEFORE indexing the table. A bad syscall number is a
     * hostile input, not a bug - return an error and stay alive.
     * Lab 2 (trace) hooks in HERE: this is the one point every call crosses. */
    if (num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
        uint64 a0 = p->tf->a0;
        p->tf->a0 = syscalls[num]();
        trace_record((int)num, (long)p->tf->a0, a0);   /* Lab 2 */
        p->syscall_count++; usysinfo_update(p);         /* Lab 3 */
    } else {
        printf("pid %d (%s): unknown syscall %d\n", p->pid, p->name, num);
        p->tf->a0 = -1;
    }
    (void)syscall_name;      /* used by Lab 2; referenced here to stay warning-clean */
}
