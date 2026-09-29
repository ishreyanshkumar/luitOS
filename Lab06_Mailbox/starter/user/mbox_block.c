#include "user/ulib.h"

static void
fail(const char *msg)
{
    printf("mbox_block: FAIL: %s\n", msg);
    exit(1);
}

static int
read_int(int fd)
{
    int v = -999;
    if (read(fd, &v, sizeof(v)) != sizeof(v))
        fail("pipe read failed");
    return v;
}

static void
write_int(int fd, int v)
{
    if (write(fd, &v, sizeof(v)) != sizeof(v))
        exit(2);
}

static void
wait_child_ok(void)
{
    if (wait(0) < 0)
        fail("wait failed");
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;
    int p[2];
    int pid;

    /* Mailbox 2: an empty receiver must sleep, then wake after a send. */
    if (pipe(p) < 0)
        fail("pipe failed");
    pid = fork();
    if (pid < 0)
        fail("fork failed");
    if (pid == 0) {
        close(p[0]);
        int v = mbox_recv(2);
        write_int(p[1], v);
        close(p[1]);
        exit(v == 42 ? 0 : 1);
    }
    close(p[1]);
    sleep(10);
    if (mbox_send(2, 42) != 0)
        fail("send to waiting receiver failed");
    if (read_int(p[0]) != 42)
        fail("waiting receiver got wrong value");
    close(p[0]);
    wait_child_ok();
    if (mbox_close(2) != 0)
        fail("close mailbox 2 failed");

    /* Mailbox 3: a full sender must sleep until a receiver creates space. */
    for (int i = 0; i < 8; i++)
        if (mbox_send(3, i) != 0)
            fail("could not fill mailbox 3");
    if (pipe(p) < 0)
        fail("pipe failed");
    pid = fork();
    if (pid < 0)
        fail("fork failed");
    if (pid == 0) {
        close(p[0]);
        int rc = mbox_send(3, 99);
        write_int(p[1], rc);
        close(p[1]);
        exit(rc == 0 ? 0 : 1);
    }
    close(p[1]);
    sleep(10);
    if (mbox_recv(3) != 0)
        fail("wrong oldest value while unblocking sender");
    if (read_int(p[0]) != 0)
        fail("blocked sender did not complete");
    close(p[0]);
    wait_child_ok();
    for (int i = 1; i < 8; i++)
        if (mbox_recv(3) != i)
            fail("FIFO order broken after sender wakeup");
    if (mbox_recv(3) != 99)
        fail("woken sender value missing");
    if (mbox_close(3) != 0)
        fail("close mailbox 3 failed");

    /* Mailbox 4: close must wake a receiver blocked on empty. */
    if (pipe(p) < 0)
        fail("pipe failed");
    pid = fork();
    if (pid < 0)
        fail("fork failed");
    if (pid == 0) {
        close(p[0]);
        int v = mbox_recv(4);
        write_int(p[1], v);
        close(p[1]);
        exit(v == -1 ? 0 : 1);
    }
    close(p[1]);
    sleep(10);
    if (mbox_close(4) != 0)
        fail("close mailbox 4 failed");
    if (read_int(p[0]) != -1)
        fail("close did not release blocked receiver");
    close(p[0]);
    wait_child_ok();

    /* Mailbox 5: close must wake a sender blocked on full. */
    for (int i = 0; i < 8; i++)
        if (mbox_send(5, 100 + i) != 0)
            fail("could not fill mailbox 5");
    if (pipe(p) < 0)
        fail("pipe failed");
    pid = fork();
    if (pid < 0)
        fail("fork failed");
    if (pid == 0) {
        close(p[0]);
        int rc = mbox_send(5, 999);
        write_int(p[1], rc);
        close(p[1]);
        exit(rc == -1 ? 0 : 1);
    }
    close(p[1]);
    sleep(10);
    if (mbox_close(5) != 0)
        fail("close mailbox 5 failed");
    if (read_int(p[0]) != -1)
        fail("close did not release blocked sender");
    close(p[0]);
    wait_child_ok();
    for (int i = 0; i < 8; i++)
        if (mbox_recv(5) != 100 + i)
            fail("buffered values lost after close");
    if (mbox_recv(5) != -1)
        fail("mailbox 5 did not become drained");

    printf("MBOX_BLOCK: PASS\n");
    exit(0);
}
