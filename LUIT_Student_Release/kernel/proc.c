/* PROCESSES, SCHEDULING, SMP. */
#include "types.h"
#include "defs.h"
#include "hal.h"
#include "pstat.h"

struct cpu   cpus[NCPU];
struct proc  proc[NPROC];

/* KERNEL STACKS.
 *
 * BUG WORTH UNDERSTANDING (we hit it building this reference kernel):
 * do NOT build a 4-page kernel stack by calling palloc() four times. palloc()
 * returns pages from a free list - they are NOT contiguous. The stack would run
 * off the end of the first page into memory that is still on the free list,
 * which palloc() then happily hands to someone else. In our case it handed out
 * a page of the kernel's own page table, the stack overwrote it, and we got a
 * load page fault in an address that "was definitely mapped."
 *
 * A kernel stack must be CONTIGUOUS. Carve it out of BSS, where the linker
 * guarantees that.
 */
#define KSTACK_PAGES 4
#define KSTACK_SIZE  (KSTACK_PAGES * PGSIZE)
static char kstacks[NPROC][KSTACK_SIZE] __attribute__((aligned(4096)));
static struct spinlock pid_lock;
static struct spinlock wait_lock;   /* protects parent pointers */
static int   nextpid = 1;
struct proc *initproc;

extern void forkret_asm(void);

/* tp holds the hart id (set in entry.S). Safe only with interrupts off -
 * otherwise we could be moved to another hart between read and use. */
struct cpu *mycpu(void) { return &cpus[hal_hart_id()]; }

struct proc *myproc(void)
{
    push_off();
    struct proc *p = mycpu()->proc;
    pop_off();
    return p;
}

static int allocpid(void)
{
    acquire(&pid_lock);
    int pid = nextpid++;
    release(&pid_lock);
    return pid;
}

void procinit(void)
{
    initlock(&pid_lock,  "nextpid");
    initlock(&wait_lock, "wait_lock");
    initlock(&tickslock, "time");
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
        initlock(&p->lock, "proc");
        p->state  = UNUSED;
        p->kstack = 0;
    }
}

static void freeproc(struct proc *p)
{
    if (p->tf) pfree((void *)p->tf);
    p->tf = 0;
    if (p->pagetable) uvmfree(p->pagetable, p->sz);
    p->pagetable = 0;
    p->kstack = 0;              /* statically allocated - nothing to free */
    p->sz = 0; p->pid = 0; p->parent = 0;
    p->name[0] = 0; p->chan = 0; p->killed = 0; p->xstate = 0;
    p->state = UNUSED;
}

/* First thing a brand-new process runs. It must release the lock scheduler()
 * acquired for us - a subtlety that trips up everyone the first time. */
static void forkret(void)
{
    static int first = 1;
    release(&myproc()->lock);
    if (first) {
        /* The filesystem cannot be initialized from main(): reading the
         * superblock SLEEPS on disk I/O, and only a process can sleep.
         * So the first process to run does it, exactly once. */
        first = 0;
        fsinit(ROOTDEV);
        myproc()->cwd = namei("/");
        __sync_synchronize();
    }
    usertrapret();
}

static struct proc *allocproc(void)
{
    struct proc *p;
    for (p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->state == UNUSED) goto found;
        release(&p->lock);
    }
    return 0;

found:
    p->pid    = allocpid();
    p->state  = USED;
    p->killed = 0;
    p->xstate = 0;
    p->chan   = 0;

    if ((p->tf = (struct trapframe *)palloc()) == 0) { freeproc(p); release(&p->lock); return 0; }

    /* Contiguous, statically reserved. See the note at the top of this file. */
    p->kstack = (uint64)kstacks[p - proc];

    p->pagetable = uvmcreate();
    if (!p->pagetable) { freeproc(p); release(&p->lock); return 0; }

    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64)forkret;
    p->context.sp = p->kstack + KSTACK_SIZE;
    return p;
}

/* --- the very first user process, built by hand --- */
extern char _binary_user_initcode_start[], _binary_user_initcode_end[];

void userinit(void)
{
    struct proc *p = allocproc();
    if (!p) panic("userinit: allocproc failed");
    initproc = p;

    uint64 sz = (uint64)(_binary_user_initcode_end - _binary_user_initcode_start);
    if (sz > PGSIZE) panic("userinit: initcode too big");

    char *mem = palloc();
    memset(mem, 0, PGSIZE);
    memmove(mem, _binary_user_initcode_start, sz);
    mappages(p->pagetable, 0, PGSIZE, (uint64)mem, PTE_R | PTE_W | PTE_X | PTE_U);

    char *stack = palloc();
    memset(stack, 0, PGSIZE);
    mappages(p->pagetable, PGSIZE, PGSIZE, (uint64)stack, PTE_R | PTE_W | PTE_U);

    p->sz       = 2 * PGSIZE;
    p->tf->epc  = 0;                    /* start at the first byte of initcode */
    p->tf->sp   = 2 * PGSIZE;           /* stack grows down from the top       */
    strncpy(p->name, "initcode", sizeof(p->name));
    /* p->cwd is set by forkret once the filesystem is initialized. */
    p->state    = RUNNABLE;
    release(&p->lock);
}

int growproc(int n)
{
    struct proc *p = myproc();
    uint64 sz = p->sz;

    if (n > 0) {
        for (uint64 a = PGROUNDUP(sz); a < sz + n; a += PGSIZE) {
            char *mem = palloc();
            if (!mem) return -1;
            memset(mem, 0, PGSIZE);
            if (mappages(p->pagetable, a, PGSIZE, (uint64)mem,
                         PTE_R | PTE_W | PTE_U) != 0) {
                pfree(mem);
                return -1;
            }
        }
    } else if (n < 0) {
        uint64 newsz = sz + n;
        if (PGROUNDUP(newsz) < PGROUNDUP(sz))
            uvmunmap(p->pagetable, PGROUNDUP(newsz),
                     (PGROUNDUP(sz) - PGROUNDUP(newsz)) / PGSIZE, 1);
        sz = newsz;
        p->sz = sz;
        return 0;
    }
    p->sz = sz + n;
    return 0;
}

int fork(void)
{
    struct proc *parent = myproc();
    struct proc *np = allocproc();
    if (!np) return -1;

    /* Implementation note. */


    if (uvmcopy(parent->pagetable, np->pagetable, parent->sz) < 0) {
        freeproc(np);
        release(&np->lock);
        return -1;
    }
    np->sz = parent->sz;
    *(np->tf) = *(parent->tf);
    np->tf->a0 = 0;                 /* the child sees fork() return 0 */

    /* The child INHERITS the parent's open files and cwd - this is what makes
     * `cmd > file` work: the shell redirects, then forks, and the child keeps
     * the redirected descriptor. Same struct file, same offset. */
    for (int i = 0; i < NOFILE; i++)
        if (parent->ofile[i])
            np->ofile[i] = filedup(parent->ofile[i]);
    np->cwd = idup(parent->cwd);

    strncpy(np->name, parent->name, sizeof(np->name));
    int pid = np->pid;
    release(&np->lock);

    acquire(&wait_lock);
    np->parent = parent;
    release(&wait_lock);

    acquire(&np->lock);
    np->state = RUNNABLE;
    release(&np->lock);
    return pid;
}

static void reparent(struct proc *p)
{
    for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
        if (pp->parent == p) {
            pp->parent = initproc;
            wakeup(initproc);
        }
    }
}

void exit(int status)
{
    struct proc *p = myproc();
    if (p == initproc) panic("init exiting");

    /* Close every open file. Do this BEFORE becoming a zombie: fileclose may
     * sleep (iput -> disk I/O), and zombies must never sleep. */
    for (int fd = 0; fd < NOFILE; fd++) {
        if (p->ofile[fd]) {
            fileclose(p->ofile[fd]);
            p->ofile[fd] = 0;
        }
    }
    iput(p->cwd);
    p->cwd = 0;

    acquire(&wait_lock);
    reparent(p);
    wakeup(p->parent);
    acquire(&p->lock);
    p->xstate = status;
    p->state  = ZOMBIE;
    release(&wait_lock);

    sched();                        /* never returns */
    panic("zombie exit");
}

int wait(uint64 addr)
{
    struct proc *p = myproc();
    acquire(&wait_lock);

    for (;;) {
        int havekids = 0;
        for (struct proc *pp = proc; pp < &proc[NPROC]; pp++) {
            if (pp->parent != p) continue;
            havekids = 1;
            acquire(&pp->lock);
            if (pp->state == ZOMBIE) {
                int pid = pp->pid;
                if (addr && copyout(p->pagetable, addr,
                                    (char *)&pp->xstate, sizeof(pp->xstate)) < 0) {
                    release(&pp->lock);
                    release(&wait_lock);
                    return -1;
                }
                freeproc(pp);
                release(&pp->lock);
                release(&wait_lock);
                return pid;
            }
            release(&pp->lock);
        }
        if (!havekids || p->killed) {
            release(&wait_lock);
            return -1;
        }
        sleep(p, &wait_lock);
    }
}

/* Implementation note. */
void scheduler(void)
{
    struct cpu *c = mycpu();
    c->proc = 0;

    for (;;) {
        intr_on();                  /* else a hart with no work sleeps forever */

        for (struct proc *p = proc; p < &proc[NPROC]; p++) {
            acquire(&p->lock);
            if (p->state == RUNNABLE) {
                p->state = RUNNING;
                c->proc  = p;
                w_satp(MAKE_SATP(p->pagetable));   /* into its address space */
                sfence_vma();

                swtch(&c->context, &p->context);

                w_satp(MAKE_SATP(kernel_pagetable));
                sfence_vma();
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}

/* Switch to the scheduler. Must hold p->lock and have changed p->state. */
void sched(void)
{
    struct proc *p = myproc();
    if (!holding(&p->lock))   panic("sched: not holding p->lock");
    if (mycpu()->noff != 1)   panic("sched: holding another lock too");
    if (p->state == RUNNING)  panic("sched: process is still RUNNING");
    if (intr_get())           panic("sched: interrupts are on");

    int intena = mycpu()->intena;
    swtch(&p->context, &mycpu()->context);
    mycpu()->intena = intena;
}

void yield(void)
{
    struct proc *p = myproc();
    acquire(&p->lock);
    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

void sleep(void *chan, struct spinlock *lk)
{
    struct proc *p = myproc();

    /* Acquire p->lock BEFORE releasing lk. If we did it the other way round, a
     * wakeup could slip in between and be lost - the classic missed-wakeup race. */
    acquire(&p->lock);
    release(lk);

    p->chan  = chan;
    p->state = SLEEPING;
    sched();

    p->chan = 0;
    release(&p->lock);
    acquire(lk);
}

void wakeup(void *chan)
{
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
                p->state = RUNNABLE;
            release(&p->lock);
        }
    }
}

int kill(int pid)
{
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->pid == pid) {
            p->killed = 1;
            if (p->state == SLEEPING) p->state = RUNNABLE;
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    }
    return -1;
}

/* Copy up to max process records to user space; returns the count. Backs the
 * procstat() syscall and the `ps` utility. Reads are racy-by-design (a
 * snapshot, not a transaction) but each slot is read under its own lock. */
int procstat(uint64 uaddr, int max)
{
    struct pstat ps;
    int n = 0;
    for (struct proc *p = proc; p < &proc[NPROC] && n < max; p++) {
        acquire(&p->lock);
        if (p->state == UNUSED) { release(&p->lock); continue; }
        ps.pid   = p->pid;
        ps.state = p->state;
        memmove(ps.name, p->name, sizeof(ps.name));
        release(&p->lock);
        if (copyout(myproc()->pagetable, uaddr + n * sizeof(ps),
                    (char *)&ps, sizeof(ps)) < 0)
            return -1;
        n++;
    }
    return n;
}

void procdump(void)
{
    static const char *st[] = {
        [UNUSED]"unused", [USED]"used", [SLEEPING]"sleep",
        [RUNNABLE]"runble", [RUNNING]"run", [ZOMBIE]"zombie"
    };
    printf("\n--- process table ---\n");
    for (struct proc *p = proc; p < &proc[NPROC]; p++) {
        if (p->state == UNUSED) continue;
        printf("pid %d %s %s\n", p->pid, st[p->state], p->name);
    }
}
