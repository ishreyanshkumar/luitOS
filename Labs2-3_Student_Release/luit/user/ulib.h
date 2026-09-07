#ifndef LUIT_ULIB_H
#define LUIT_ULIB_H
/* luitc - the tiny user-space C library, plus the syscall stubs (usys.S). */
typedef unsigned char  uint8;
typedef unsigned short uint16;
typedef unsigned int   uint32;
typedef unsigned long  uint64;

#include "../kernel/stat.h"
#include "../kernel/fcntl.h"
#include "../kernel/pstat.h"

/* system calls - every one of these is an ecall (see kernel/syscall.tbl) */
int  fork(void);
int  exit(int) __attribute__((noreturn));
int  wait(int *);
int  pipe(int *);
int  read(int, void *, int);
int  kill(int);
int  exec(const char *, char **);
int  fstat(int fd, struct stat *);
int  chdir(const char *);
int  dup(int);
int  getpid(void);
char *sbrk(int);
int  sleep(int);
int  uptime(void);
int  open(const char *, int);
int  write(int, const void *, int);
int  unlink(const char *);
int  link(const char *, const char *);
int  mkdir(const char *);
int  close(int);
int  freepages(void);
int  procstat(struct pstat *, int);
struct trace_event { int pid, hart, num; long ret; unsigned long ts, arg0; };
int  tracectl(int action, unsigned long filter);
int  traceread(struct trace_event *buf, int max);
#define USYSINFO_VERSION 1
#define USYSINFO_VA 0x7FFFF000UL
struct usysinfo { unsigned int version; volatile unsigned int seq; int pid,ppid,hart; unsigned long ticks,syscall_count,ctxsw_count; unsigned int state_gen,_pad; };
int u_snapshot(struct usysinfo *out);
int u_getpid(void);
unsigned long u_uptime(void);
struct pgref { int refcount; int cow; int writable; };
int pgrefstat(unsigned long va, struct pgref *out);
int pgaudit(void);

/* Lab 6: threads & futex */
int clone(unsigned long fn, unsigned long arg, unsigned long stack);
int gettid(void);
int futex(unsigned long addr, int op, unsigned long val, int n);
int thread_create(void (*fn)(void*), void *arg, void *stack);
void mutex_lock(unsigned long *m);
void mutex_unlock(unsigned long *m);

/* Lab 1: diagnostics */
struct abinfo { int num; char name[16]; };
int fdstat(int pid, int fd, struct fdinfo *out);
int abimeta(struct abinfo *buf, int max);

/* Lab 4: user-level event delivery */
int sigalarm(int interval, void (*handler)());
int sigreturn(void);
int event_stack(void *sp, int size);

/* Lab 8: allocator instrumentation */
struct allocstat { unsigned long acquires[8]; unsigned long allocs[8]; unsigned long frees[8]; int nfree; int total; };
int alloc_stats(struct allocstat *out);
int alloc_audit(void);

/* Lab 9: rename */
int rename(const char *old, const char *new);

/* Lab 10: mmap */
#define PROT_READ  0x1
#define PROT_WRITE 0x2
#define MAP_SHARED  0x1
#define MAP_PRIVATE 0x2
char *mmap(void *addr, unsigned long len, int prot, int flags, int fd, unsigned long off);
int munmap(void *addr, unsigned long len);
int logtest(void);
int logcrash(void);
int logverify(void);
int fsck(void);

/* library, not syscalls */
int   stat(const char *path, struct stat *st);
void  printf(const char *, ...);
void  fprintf(int fd, const char *, ...);
int   strcmp(const char *, const char *);
int   strlen(const char *);
char *strcpy(char *, const char *);
char *strchr(const char *, char);
int   atoi(const char *);
void *memset(void *, int, int);
void *memmove(void *, const void *, int);
char *gets(char *, int);
void *malloc(int);
void  free(void *);
#endif
