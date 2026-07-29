/* Shared kernel/user layout for the procstat() syscall (used by ps). */
#ifndef LUIT_PSTAT_H
#define LUIT_PSTAT_H
struct pstat {
    int  pid;
    int  state;        /* enum procstate value */
    char name[16];
};
#endif
