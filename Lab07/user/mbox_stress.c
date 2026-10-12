#include "ulib.h"

#define NPROD 4
#define NCONS 4
#define PER_PROD 200
#define TOTAL (NPROD * PER_PROD)
#define PER_CONS (TOTAL / NCONS)

static void
fail(const char *msg)
{
    printf("mbox_stress: FAIL: %s\n", msg);
    exit(1);
}

static void
write_int(int fd, int v)
{
    if (write(fd, &v, sizeof(v)) != sizeof(v))
        exit(2);
}

static int
read_int(int fd)
{
    int v = -1;
    if (read(fd, &v, sizeof(v)) != sizeof(v))
        fail("result pipe read failed");
    return v;
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    /* Mailbox 6 is used only by this program. */
    static char seen[TOTAL];
    int result[2];
    int children = 0;

    if (pipe(result) < 0)
        fail("pipe failed");

    /* Several producers contend for the same bounded mailbox. */
    for (int p = 0; p < NPROD; p++) {
        int pid = fork();
        if (pid < 0)
            fail("producer fork failed");
        if (pid == 0) {
            close(result[0]);
            close(result[1]);
            for (int s = 0; s < PER_PROD; s++) {
                int value = p * PER_PROD + s;
                if (mbox_send(6, value) != 0)
                    exit(1);
            }
            exit(0);
        }
        children++;
    }

    /* Several consumers contend for the same data and report results to parent. */
    for (int c = 0; c < NCONS; c++) {
        int pid = fork();
        if (pid < 0)
            fail("consumer fork failed");
        if (pid == 0) {
            close(result[0]);
            for (int i = 0; i < PER_CONS; i++) {
                int v = mbox_recv(6);
                write_int(result[1], v);
                if (v < 0)
                    exit(1);
            }
            close(result[1]);
            exit(0);
        }
        children++;
    }

    close(result[1]);

    for (int i = 0; i < TOTAL; i++) {
        int v = read_int(result[0]);
        if (v < 0 || v >= TOTAL)
            fail("received out-of-range value");
        if (seen[v])
            fail("duplicate value received");
        seen[v] = 1;
    }
    close(result[0]);

    for (int i = 0; i < children; i++)
        if (wait(0) < 0)
            fail("wait failed");

    for (int i = 0; i < TOTAL; i++)
        if (!seen[i])
            fail("message missing");

    if (mbox_close(6) != 0 || mbox_recv(6) != -1)
        fail("final close/drain check failed");

    printf("mbox_stress: producers=%d consumers=%d received=%d unique=%d\n",
           NPROD, NCONS, TOTAL, TOTAL);
    printf("MBOX_STRESS: PASS\n");
    exit(0);
}
