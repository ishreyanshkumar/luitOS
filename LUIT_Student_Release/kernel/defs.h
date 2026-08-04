#ifndef LUIT_DEFS_H
#define LUIT_DEFS_H
#include "types.h"
#include "riscv.h"
#include "stat.h"

#include "param.h"

/* ---- fdt.c ---- */
enum { PEND_NONE = 0, PEND_UART, PEND_PLIC, PEND_VIRTIO, PEND_MEM };
#define FDT_MAX_VIRTIO 8
struct fdt_info {
    uint64 blob, blob_size;
    uint64 uart_base, plic_base;
    int    uart_irq;
    uint64 virtio_base[FDT_MAX_VIRTIO];   /* qemu virt has 8 slots; probe them */
    int    virtio_irq[FDT_MAX_VIRTIO];
    int    nvirtio;
    uint64 mem_base, mem_size;
    int    ncpu;
    int    pending;
};
extern struct fdt_info fdt;
void  fdt_init(uint64 fdt_pa);

/* ---- sbi.c ---- */
void  sbi_putchar(int c);
void  sbi_set_timer(uint64 stime);
long  sbi_hart_start(uint64 hartid, uint64 addr, uint64 opaque);

/* ---- printf.c ---- */
void  printf(const char *fmt, ...);
void  panic(const char *s) __attribute__((noreturn));
void  printfinit(void);

/* ---- string.c ---- */
void *memset(void *dst, int c, usize n);
void *memmove(void *dst, const void *src, usize n);
int   memcmp(const void *a, const void *b, usize n);
int   strncmp(const char *a, const char *b, usize n);
char *strncpy(char *d, const char *s, int n);
int   strlen(const char *s);

/* ---- palloc.c ---- */
void  palloc_init(void);
void *palloc(void);
void  pfree(void *pa);
int   palloc_free_count(void);
void  palloc_ref_inc(void *pa);          /* Implementation note. */
int   palloc_ref_get(void *pa);

/* ---- spinlock.c ---- */
struct spinlock { uint32 locked; const char *name; int cpu; };
void  initlock(struct spinlock *lk, const char *name);
void  acquire(struct spinlock *lk);
void  release(struct spinlock *lk);
int   holding(struct spinlock *lk);
void  push_off(void);
void  pop_off(void);

/* ---- trap.c ---- */
void  trapinit_hart(void);
void  kerneltrap(void);
void  usertrap(void);
void  usertrapret(void);
extern struct spinlock tickslock;
extern uint64 ticks;

/* ---- vm.c ---- */
void        kvminit(void);
void        kvminithart(void);
pte_t      *walk(pagetable_t pt, uint64 va, int alloc);
int         mappages(pagetable_t pt, uint64 va, uint64 size, uint64 pa, int perm);
uint64      walkaddr(pagetable_t pt, uint64 va);
pagetable_t uvmcreate(void);
void        uvmfree(pagetable_t pt, uint64 sz);
void        uvmunmap(pagetable_t pt, uint64 va, uint64 npages, int do_free);
int         uvmcopy(pagetable_t old, pagetable_t new, uint64 sz);   /* Implementation note. */
int         copyout(pagetable_t pt, uint64 dstva, char *src, uint64 len);
int         copyin(pagetable_t pt, char *dst, uint64 srcva, uint64 len);
int         copyinstr(pagetable_t pt, char *dst, uint64 srcva, uint64 max);
void        vmprint(pagetable_t pt);
extern pagetable_t kernel_pagetable;
uint64      mmio_alias(uint64 pa);

/* ---- proc.c / sched.c ---- */
struct context { uint64 ra, sp, s0,s1,s2,s3,s4,s5,s6,s7,s8,s9,s10,s11; };
struct trapframe {
    /*   0 */ uint64 kernel_satp;
    /*   8 */ uint64 kernel_sp;
    /*  16 */ uint64 kernel_trap;
    /*  24 */ uint64 epc;
    /*  32 */ uint64 kernel_hartid;
    /*  40 */ uint64 ra;  uint64 sp;  uint64 gp;  uint64 tp;
    /*  72 */ uint64 t0;  uint64 t1;  uint64 t2;
    /*  96 */ uint64 s0;  uint64 s1;
    /* 112 */ uint64 a0;  uint64 a1;  uint64 a2;  uint64 a3;
    /* 144 */ uint64 a4;  uint64 a5;  uint64 a6;  uint64 a7;
    /* 176 */ uint64 s2;  uint64 s3;  uint64 s4;  uint64 s5;
    /* 208 */ uint64 s6;  uint64 s7;  uint64 s8;  uint64 s9;
    /* 240 */ uint64 s10; uint64 s11;
    /* 256 */ uint64 t3;  uint64 t4;  uint64 t5;  uint64 t6;
};
enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
struct proc {
    struct spinlock lock;
    enum procstate  state;
    void           *chan;
    int             killed;
    int             xstate;
    int             pid;
    struct proc    *parent;
    uint64          kstack;
    uint64          sz;
    pagetable_t     pagetable;
    struct trapframe *tf;
    struct context  context;
    struct file    *ofile[NOFILE];  /* open files: the fd table       */
    struct inode   *cwd;            /* current directory              */
    char            name[16];
};
struct cpu { struct proc *proc; struct context context; int noff; int intena; };
extern struct cpu cpus[NCPU];
struct cpu  *mycpu(void);
struct proc *myproc(void);
void  procinit(void);
void  userinit(void);
void  scheduler(void) __attribute__((noreturn));
void  sched(void);
void  yield(void);
void  sleep(void *chan, struct spinlock *lk);
void  wakeup(void *chan);
int   fork(void);
int   growproc(int n);
int   wait(uint64 addr);
void  exit(int status) __attribute__((noreturn));
int   kill(int pid);
void  swtch(struct context *old, struct context *new);
void  procdump(void);
int   procstat(uint64 uaddr, int max);

/* ---- syscall.c ---- */
void  syscall(void);
int   argint(int n, int *ip);
int   argaddr(int n, uint64 *ap);
int   argstr(int n, char *buf, int max);
int   fetchstr(uint64 addr, char *buf, int max);

/* ---- sleeplock.c ----
 * A lock you may HOLD WHILE SLEEPING (disk I/O). Internally: a spinlock
 * guarding `locked`, plus sleep/wakeup. Never hold a spinlock across sleep. */
struct sleeplock { uint32 locked; struct spinlock lk; const char *name; int pid; };
void  initsleeplock(struct sleeplock *lk, const char *name);
void  acquiresleep(struct sleeplock *lk);
void  releasesleep(struct sleeplock *lk);
int   holdingsleep(struct sleeplock *lk);

/* ---- bio.c ---- */
#include "fs.h"
#include "buf.h"
void        binit(void);
struct buf *bread(uint32 dev, uint32 blockno);
void        bwrite(struct buf *b);
void        brelse(struct buf *b);

/* ---- fs.c ---- */
#include "file.h"
void          fsinit(int dev);
void          iinit(void);
struct inode *ialloc(uint32 dev, uint16 type);
struct inode *idup(struct inode *ip);
void          ilock(struct inode *ip);
void          iunlock(struct inode *ip);
void          iput(struct inode *ip);
void          iunlockput(struct inode *ip);
void          iupdate(struct inode *ip);
void          itrunc(struct inode *ip);
void          stati(struct inode *ip, struct stat *st);
int           readi(struct inode *ip, int user_dst, uint64 dst, uint32 off, uint32 n);
int           writei(struct inode *ip, int user_src, uint64 src, uint32 off, uint32 n);
int           namecmp(const char *s, const char *t);
struct inode *dirlookup(struct inode *dp, char *name, uint32 *poff);
int           dirlink(struct inode *dp, char *name, uint32 inum);
struct inode *namei(char *path);
struct inode *nameiparent(char *path, char *name);

/* ---- file.c ---- */
void         fileinit(void);
struct file *filealloc(void);
struct file *filedup(struct file *f);
void         fileclose(struct file *f);
int          filestat(struct file *f, uint64 uaddr);
int          fileread(struct file *f, uint64 uaddr, int n);
int          filewrite(struct file *f, uint64 uaddr, int n);

/* ---- pipe.c ---- */
struct pipe;
int   pipealloc(struct file **f0, struct file **f1);
void  pipeclose(struct pipe *pi, int writable);
int   piperead(struct pipe *pi, uint64 uaddr, int n);
int   pipewrite(struct pipe *pi, uint64 uaddr, int n);

/* ---- syscall.tbl (generated) ---- */
#include "syscallnums.h"

/* ---- exec.c ---- */
int   exec(char *path, char **argv);

/* ---- console.c ---- */
void  consoleinit(void);
void  consoleintr(int c);
int   consoleread(uint64 dst, int n);
int   consolewrite(uint64 src, int n);

/* ---- main.c ---- */
void  start(uint64 hartid, uint64 fdt_pa);

#endif
