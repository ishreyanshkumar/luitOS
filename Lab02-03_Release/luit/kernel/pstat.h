/* Shared kernel/user layout for the procstat() syscall (used by ps). */
#ifndef LUIT_PSTAT_H
#define LUIT_PSTAT_H
struct pstat {
    int  pid;
    int  ppid;         /* Lab 1: parent pid */
    int  state;        /* enum procstate value */
    char name[16];
};

/* Lab 1: fdstat() layout */
struct fdinfo { int type; int inum; int off; int readable; int writable; };

#endif
