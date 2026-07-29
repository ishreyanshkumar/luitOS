/* init - the first real program. Opens the console as fds 0/1/2, starts the
 * shell, and adopts+reaps every orphaned process forever. PID 1 never exits. */
#include "ulib.h"

int main(void)
{
    /* /console is a device inode mkfs created. Three opens? No - one open,
     * two dups: all three descriptors share one struct file. */
    if (open("/console", O_RDWR) < 0)
        exit(1);
    dup(0);  /* stdout */
    dup(0);  /* stderr */

    printf("init: starting BrahmaputraOS userland\n");

    for (;;) {
        int pid = fork();
        if (pid < 0) { printf("init: fork failed\n"); exit(1); }
        if (pid == 0) {
            char *argv[] = { "sh", 0 };
            exec("/sh", argv);
            printf("init: exec /sh failed\n");
            exit(1);
        }
        /* Reap children - ours (the shell) and everyone else's orphans,
         * reparented to us by the kernel. Restart the shell if it exits. */
        for (;;) {
            int wpid = wait(0);
            if (wpid == pid) break;      /* the shell died; loop restarts it */
            if (wpid < 0) { printf("init: wait error\n"); exit(1); }
            /* an orphan: nothing to do beyond reaping it */
        }
    }
}
