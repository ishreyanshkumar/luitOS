#include "ulib.h"

static void
fail(const char *msg)
{
    fprintf(2, "STRIDE_API: FAIL: %s\n", msg);
    exit(1);
}

static int
write_full(int fd, const void *buf, int n)
{
    const char *p = (const char *)buf;
    int off = 0;
    while (off < n) {
        int r = write(fd, p + off, n - off);
        if (r <= 0) return -1;
        off += r;
    }
    return 0;
}

static int
read_full(int fd, void *buf, int n)
{
    char *p = (char *)buf;
    int off = 0;
    while (off < n) {
        int r = read(fd, p + off, n - off);
        if (r <= 0) return -1;
        off += r;
    }
    return 0;
}

int
main(void)
{
    struct schedinfo s;
    if (schedinfo(&s) < 0) fail("schedinfo on current process");
    if (s.tickets != STRIDE_DEFAULT_TICKETS) fail("default tickets");
    if (s.stride != STRIDE_BIG / STRIDE_DEFAULT_TICKETS) fail("default stride");

    if (settickets(0) != -1) fail("accepted zero tickets");
    if (settickets(-1) != -1) fail("accepted negative tickets");
    if (settickets(STRIDE_MAX_TICKETS + 1) != -1) fail("accepted too many tickets");
    if (schedinfo(&s) < 0 || s.tickets != STRIDE_DEFAULT_TICKETS)
        fail("invalid request changed policy");

    if (settickets(250) != 0) fail("settickets(250)");
    if (schedinfo(&s) < 0) fail("schedinfo after settickets");
    if (s.tickets != 250 || s.stride != STRIDE_BIG / 250)
        fail("ticket/stride update");

    int fds[2];
    if (pipe(fds) < 0) fail("pipe");
    int pid = fork();
    if (pid < 0) fail("fork");
    if (pid == 0) {
        close(fds[0]);
        struct schedinfo c;
        if (schedinfo(&c) < 0) exit(2);
        if (write_full(fds[1], &c, sizeof(c)) < 0) exit(3);
        close(fds[1]);
        exit(0);
    }

    close(fds[1]);
    struct schedinfo c;
    if (read_full(fds[0], &c, sizeof(c)) < 0) fail("child report");
    close(fds[0]);
    if (wait(0) != pid) fail("wait child");
    if (c.tickets != 250 || c.stride != STRIDE_BIG / 250)
        fail("child did not inherit tickets");
    if (c.dispatches == 0) fail("child dispatch counter");

    printf("STRIDE_API: PASS\n");
    exit(0);
}
