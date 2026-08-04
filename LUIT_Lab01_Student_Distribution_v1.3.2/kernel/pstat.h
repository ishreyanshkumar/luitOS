/* Shared kernel/user layout for the procstat() syscall (used by ps/pstree). */
#ifndef LUIT_PSTAT_H
#define LUIT_PSTAT_H
struct pstat {
    int  pid;
    int  ppid;         /* 0 for init / no parent visible in the snapshot */
    int  state;        /* enum procstate value */
    char name[16];
};
#endif
