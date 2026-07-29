/* Implementation note. */














#include "types.h"
#include "defs.h"

struct pipe {
    struct spinlock lock;
    char   data[PIPESIZE];
    uint32 nread;       /* total bytes ever read    */
    uint32 nwrite;      /* total bytes ever written */
    int    readopen;
    int    writeopen;
};

int pipealloc(struct file **f0, struct file **f1)
{
    struct pipe *pi = 0;
    *f0 = *f1 = 0;

    if ((*f0 = filealloc()) == 0) goto bad;
    if ((*f1 = filealloc()) == 0) goto bad;
    if ((pi = (struct pipe *)palloc()) == 0) goto bad;

    pi->readopen  = 1;
    pi->writeopen = 1;
    pi->nread  = 0;
    pi->nwrite = 0;
    initlock(&pi->lock, "pipe");

    (*f0)->type = FD_PIPE; (*f0)->readable = 1; (*f0)->writable = 0; (*f0)->pipe = pi;
    (*f1)->type = FD_PIPE; (*f1)->readable = 0; (*f1)->writable = 1; (*f1)->pipe = pi;
    return 0;

bad:
    if (*f0) fileclose(*f0);
    if (*f1) fileclose(*f1);
    return -1;
}

void pipeclose(struct pipe *pi, int writable)
{
    acquire(&pi->lock);
    if (writable) {
        pi->writeopen = 0;
        wakeup(&pi->nread);          /* blocked readers must see EOF */
    } else {
        pi->readopen = 0;
        wakeup(&pi->nwrite);         /* blocked writers must see the error */
    }
    if (pi->readopen == 0 && pi->writeopen == 0) {
        release(&pi->lock);
        pfree(pi);
    } else {
        release(&pi->lock);
    }
}

int pipewrite(struct pipe *pi, uint64 uaddr, int n)
{
    struct proc *pr = myproc();
    int i = 0;

    acquire(&pi->lock);
    while (i < n) {
        if (pi->readopen == 0 || pr->killed) {
            release(&pi->lock);
            return -1;
        }
        if (pi->nwrite == pi->nread + PIPESIZE) {   /* full */
            wakeup(&pi->nread);
            sleep(&pi->nwrite, &pi->lock);
        } else {
            char ch;
            if (copyin(pr->pagetable, &ch, uaddr + i, 1) < 0) break;
            pi->data[pi->nwrite++ % PIPESIZE] = ch;
            i++;
        }
    }
    wakeup(&pi->nread);
    release(&pi->lock);
    return i;
}

int piperead(struct pipe *pi, uint64 uaddr, int n)
{
    struct proc *pr = myproc();

    acquire(&pi->lock);
    while (pi->nread == pi->nwrite && pi->writeopen) {  /* empty, not EOF */
        if (pr->killed) { release(&pi->lock); return -1; }
        sleep(&pi->nread, &pi->lock);
    }
    int i;
    for (i = 0; i < n; i++) {
        if (pi->nread == pi->nwrite) break;             /* drained */
        char ch = pi->data[pi->nread++ % PIPESIZE];
        if (copyout(pr->pagetable, uaddr + i, &ch, 1) < 0) break;
    }
    wakeup(&pi->nwrite);
    release(&pi->lock);
    return i;                                           /* 0 here = EOF */
}
