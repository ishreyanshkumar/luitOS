/* GENERATED from kernel/syscall.tbl. Included ONLY by syscall.c. */
extern uint64 sys_fork(void);
extern uint64 sys_exit(void);
extern uint64 sys_wait(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_kill(void);
extern uint64 sys_exec(void);
extern uint64 sys_fstat(void);
extern uint64 sys_chdir(void);
extern uint64 sys_dup(void);
extern uint64 sys_getpid(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_uptime(void);
extern uint64 sys_open(void);
extern uint64 sys_write(void);
extern uint64 sys_unlink(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_close(void);
extern uint64 sys_freepages(void);
extern uint64 sys_procstat(void);
static uint64 (*syscalls[])(void) = {
    [1] sys_fork,
    [2] sys_exit,
    [3] sys_wait,
    [4] sys_pipe,
    [5] sys_read,
    [6] sys_kill,
    [7] sys_exec,
    [8] sys_fstat,
    [9] sys_chdir,
    [10] sys_dup,
    [11] sys_getpid,
    [12] sys_sbrk,
    [13] sys_sleep,
    [14] sys_uptime,
    [15] sys_open,
    [16] sys_write,
    [18] sys_unlink,
    [19] sys_link,
    [20] sys_mkdir,
    [21] sys_close,
    [22] sys_freepages,
    [23] sys_procstat,
};
static const char *syscall_names[] = {
    [1] "fork",
    [2] "exit",
    [3] "wait",
    [4] "pipe",
    [5] "read",
    [6] "kill",
    [7] "exec",
    [8] "fstat",
    [9] "chdir",
    [10] "dup",
    [11] "getpid",
    [12] "sbrk",
    [13] "sleep",
    [14] "uptime",
    [15] "open",
    [16] "write",
    [18] "unlink",
    [19] "link",
    [20] "mkdir",
    [21] "close",
    [22] "freepages",
    [23] "procstat",
};
/* Implementation note. */
static inline const char *syscall_name(int n){ return (n > 0 && n < (int)(sizeof(syscall_names)/sizeof(char*)) && syscall_names[n]) ? syscall_names[n] : "?"; }
