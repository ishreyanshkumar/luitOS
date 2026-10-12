#include "ulib.h"

static void
fail(const char *msg)
{
    printf("mbox_basic: FAIL: %s\n", msg);
    exit(1);
}

int
main(int argc, char **argv)
{
    (void)argc;
    (void)argv;

    /* Mailbox 0: argument boundaries, basic FIFO, and idempotent close. */
    if (mbox_send(-1, 1) != -1 || mbox_send(8, 1) != -1)
        fail("invalid mailbox accepted by send");
    if (mbox_recv(-1) != -1 || mbox_recv(8) != -1)
        fail("invalid mailbox accepted by recv");
    if (mbox_close(-1) != -1 || mbox_close(8) != -1)
        fail("invalid mailbox accepted by close");
    if (mbox_send(0, -1) != -1)
        fail("negative message accepted");

    /* The largest legal message must remain distinguishable from -1. */
    if (mbox_send(0, 2147483647) != 0 || mbox_recv(0) != 2147483647)
        fail("INT_MAX boundary failed");

    if (mbox_send(0, 11) != 0 ||
        mbox_send(0, 22) != 0 ||
        mbox_send(0, 33) != 0)
        fail("send failed on open mailbox");

    if (mbox_recv(0) != 11 || mbox_recv(0) != 22 || mbox_recv(0) != 33)
        fail("FIFO order violated");

    if (mbox_close(0) != 0 || mbox_close(0) != 0)
        fail("close is not idempotent");
    if (mbox_send(0, 44) != -1)
        fail("send succeeded after close");
    if (mbox_recv(0) != -1)
        fail("closed and drained mailbox did not return -1");

    /* Mailbox 1: force ring wraparound, then close and drain in FIFO order. */
    for (int i = 0; i < 8; i++)
        if (mbox_send(1, i) != 0)
            fail("could not fill mailbox 1");

    for (int i = 0; i < 4; i++)
        if (mbox_recv(1) != i)
            fail("wrong value before wraparound");

    for (int i = 8; i < 12; i++)
        if (mbox_send(1, i) != 0)
            fail("send failed during wraparound");

    if (mbox_close(1) != 0)
        fail("close failed");

    for (int i = 4; i < 12; i++)
        if (mbox_recv(1) != i)
            fail("wraparound/close-and-drain FIFO violated");

    if (mbox_recv(1) != -1)
        fail("closed mailbox did not end after drain");

    printf("MBOX_BASIC: PASS\n");
    exit(0);
}
