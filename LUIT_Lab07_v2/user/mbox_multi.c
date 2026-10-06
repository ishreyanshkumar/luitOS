#include "ulib.h"

#define NWAIT 4

static void
fail(const char *msg)
{
    printf("mbox_multi: FAIL: %s\n", msg);
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
    int v = -999;
    if (read(fd, &v, sizeof(v)) != sizeof(v))
        fail("result pipe read failed");
    return v;
}

static void
wait_n(int n)
{
    for (int i = 0; i < n; i++)
        if (wait(0) < 0)
            fail("wait failed");
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;
    int p[2];

    /* Mailbox 0: several receivers wait on one empty queue.  Insert only
       one item at a time; a correct while-loop lets exactly one receiver
       make progress for each insertion even though wakeup may wake many. */
    if (pipe(p) < 0)
        fail("pipe failed");
    for (int i = 0; i < NWAIT; i++) {
        int pid = fork();
        if (pid < 0)
            fail("receiver fork failed");
        if (pid == 0) {
            close(p[0]);
            int v = mbox_recv(0);
            write_int(p[1], v);
            close(p[1]);
            exit(v >= 700 && v < 700 + NWAIT ? 0 : 1);
        }
    }
    close(p[1]);
    sleep(10);
    for (int i = 0; i < NWAIT; i++) {
        if (mbox_send(0, 700 + i) != 0)
            fail("send to waiting receivers failed");
        if (read_int(p[0]) != 700 + i)
            fail("multiple receivers did not re-check empty predicate");
    }
    close(p[0]);
    wait_n(NWAIT);
    if (mbox_close(0) != 0)
        fail("close mailbox 0 failed");

    /* Mailbox 1: several senders wait on one full queue.  Free exactly one
       slot at a time and wait for one sender completion before continuing. */
    for (int i = 0; i < 8; i++)
        if (mbox_send(1, i) != 0)
            fail("could not fill mailbox 1");
    if (pipe(p) < 0)
        fail("pipe failed");
    for (int i = 0; i < NWAIT; i++) {
        int pid = fork();
        if (pid < 0)
            fail("sender fork failed");
        if (pid == 0) {
            close(p[0]);
            int rc = mbox_send(1, 100 + i);
            write_int(p[1], rc);
            close(p[1]);
            exit(rc == 0 ? 0 : 1);
        }
    }
    close(p[1]);
    sleep(10);
    for (int i = 0; i < NWAIT; i++) {
        if (mbox_recv(1) != i)
            fail("oldest value corrupted while waking senders");
        if (read_int(p[0]) != 0)
            fail("one freed slot did not let a blocked sender complete");
    }
    close(p[0]);
    wait_n(NWAIT);

    /* Original values 4..7 must still lead the queue.  The four concurrent
       sender values may appear in any relative order, but exactly once each. */
    for (int i = 4; i < 8; i++)
        if (mbox_recv(1) != i)
            fail("FIFO order of pre-existing values was lost");
    int sender_seen[NWAIT] = {0, 0, 0, 0};
    for (int i = 0; i < NWAIT; i++) {
        int v = mbox_recv(1);
        if (v < 100 || v >= 100 + NWAIT)
            fail("unexpected concurrent sender value");
        if (sender_seen[v - 100])
            fail("duplicate concurrent sender value");
        sender_seen[v - 100] = 1;
    }
    if (mbox_close(1) != 0)
        fail("close mailbox 1 failed");

    /* Mailbox 2: close must release every receiver sleeping on empty. */
    if (pipe(p) < 0)
        fail("pipe failed");
    for (int i = 0; i < NWAIT; i++) {
        int pid = fork();
        if (pid < 0)
            fail("close-receiver fork failed");
        if (pid == 0) {
            close(p[0]);
            int v = mbox_recv(2);
            write_int(p[1], v);
            close(p[1]);
            exit(v == -1 ? 0 : 1);
        }
    }
    close(p[1]);
    sleep(10);
    if (mbox_close(2) != 0)
        fail("close mailbox 2 failed");
    for (int i = 0; i < NWAIT; i++)
        if (read_int(p[0]) != -1)
            fail("close did not wake every blocked receiver");
    close(p[0]);
    wait_n(NWAIT);

    /* Mailbox 3: close must release every sender sleeping on full, while
       preserving all values that were already buffered. */
    for (int i = 0; i < 8; i++)
        if (mbox_send(3, 300 + i) != 0)
            fail("could not fill mailbox 3");
    if (pipe(p) < 0)
        fail("pipe failed");
    for (int i = 0; i < NWAIT; i++) {
        int pid = fork();
        if (pid < 0)
            fail("close-sender fork failed");
        if (pid == 0) {
            close(p[0]);
            int rc = mbox_send(3, 400 + i);
            write_int(p[1], rc);
            close(p[1]);
            exit(rc == -1 ? 0 : 1);
        }
    }
    close(p[1]);
    sleep(10);
    if (mbox_close(3) != 0)
        fail("close mailbox 3 failed");
    for (int i = 0; i < NWAIT; i++)
        if (read_int(p[0]) != -1)
            fail("close did not wake every blocked sender");
    close(p[0]);
    wait_n(NWAIT);
    for (int i = 0; i < 8; i++)
        if (mbox_recv(3) != 300 + i)
            fail("close lost or reordered buffered values");
    if (mbox_recv(3) != -1)
        fail("closed mailbox 3 did not end after drain");

    printf("MBOX_MULTI: PASS\n");
    exit(0);
}
