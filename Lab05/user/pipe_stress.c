#include "user/ulib.h"

#define NWRITERS 4
#define NWRITES  2048
#define READBUF  64

static int
all_counts_ok(int counts[NWRITERS])
{
    for (int i = 0; i < NWRITERS; i++) {
        if (counts[i] != NWRITES)
            return 0;
    }
    return 1;
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    int fds[2];
    int counts[NWRITERS] = {0, 0, 0, 0};
    int spawned = 0;
    int failed = 0;
    int total = 0;
    char buf[READBUF];

    if (pipe(fds) < 0) {
        printf("pipe_stress: pipe failed\n");
        exit(1);
    }

    for (int i = 0; i < NWRITERS; i++) {
        int pid = fork();
        if (pid < 0) {
            printf("pipe_stress: fork failed at writer %d\n", i);
            failed = 1;
            break;
        }

        if (pid == 0) {
            char token = (char)('A' + i);
            close(fds[0]);

            for (int j = 0; j < NWRITES; j++) {
                if (write(fds[1], &token, 1) != 1) {
                    printf("pipe_stress: writer %d write failed\n", i);
                    close(fds[1]);
                    exit(1);
                }
            }

            close(fds[1]);
            exit(0);
        }

        spawned++;
    }

    /* The parent never writes. Closing this descriptor is essential: EOF on
       the read side is visible only after every writer has closed its copy. */
    close(fds[1]);

    /* Give the writers time to fill a bounded pipe and reach the kernel's
       blocking path before the reader begins to drain it. */
    sleep(20);

    for (;;) {
        int n = read(fds[0], buf, sizeof(buf));
        if (n < 0) {
            printf("pipe_stress: read failed\n");
            failed = 1;
            break;
        }
        if (n == 0)
            break;

        for (int k = 0; k < n; k++) {
            int id = buf[k] - 'A';
            if (id < 0 || id >= NWRITERS) {
                printf("pipe_stress: unexpected byte %d\n", (int)buf[k]);
                failed = 1;
            } else {
                counts[id]++;
            }
            total++;
        }
    }

    close(fds[0]);

    for (int i = 0; i < spawned; i++)
        wait(0);

    printf("pipe_stress: received=%d expected=%d\n",
           total, NWRITERS * NWRITES);
    for (int i = 0; i < NWRITERS; i++)
        printf("pipe_stress: writer %d count=%d expected=%d\n",
               i, counts[i], NWRITES);

    if (!failed && spawned == NWRITERS &&
        total == NWRITERS * NWRITES && all_counts_ok(counts)) {
        printf("PIPE_STRESS: PASS\n");
        exit(0);
    }

    printf("PIPE_STRESS: FAIL\n");
    exit(1);
}
