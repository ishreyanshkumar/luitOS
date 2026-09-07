/* Implementation note. */









#include "types.h"
#include "defs.h"
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

/* ---- dispatch ---- */

#include "syscalltab.h"     /* GENERATED: syscalls[] and syscall_names[] */

void syscall(void)
{
    struct proc *p = myproc();
    uint64 num = p->tf->a7;

    /* Implementation note. */


    if (num > 0 && num < sizeof(syscalls)/sizeof(syscalls[0]) && syscalls[num]) {
        p->tf->a0 = syscalls[num]();
    } else {
        printf("pid %d (%s): unknown syscall %d\n", p->pid, p->name, num);
        p->tf->a0 = -1;
    }
    (void)syscall_name;      /* Implementation note. */
}
