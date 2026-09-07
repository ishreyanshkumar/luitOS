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
#include "../kernel/usysinfo.h"

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

/* Completed Lab 2 interface. */
struct trace_event { int pid, hart, num; long ret; unsigned long ts, arg0; };
int  tracectl(int action, unsigned long filter);
int  traceread(struct trace_event *buf, int max);

/* Lab 3: these are user-library functions, not syscalls. */
int           u_snapshot(struct usysinfo *out);
int           u_getpid(void);
unsigned long u_uptime(void);

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
