#include "ulib.h"

struct report {
    int tag;
    uint64 delta;
};

static volatile uint64 sink;

static void
fail(const char *msg)
{
    fprintf(2, "STRIDE_SHARE: FAIL: %s\n", msg);
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

static void
worker(int tag, int tickets, int startfd, int outfd, uint64 start_at, uint64 deadline)
{
    if (settickets(tickets) < 0) exit(10 + tag);
    char token;
    if (read(startfd, &token, 1) != 1) exit(20 + tag);

    while (u_uptime() < start_at)
        sink = sink * 1664525UL + 1013904223UL;

    struct schedinfo a, b;
    if (schedinfo(&a) < 0) exit(30 + tag);
    while (u_uptime() < deadline) {
        for (int i = 0; i < 4000; i++)
            sink = sink * 1103515245UL + (uint64)(tag + 1);
    }
    if (schedinfo(&b) < 0) exit(40 + tag);

    struct report r;
    r.tag = tag;
    r.delta = b.dispatches - a.dispatches;
    if (write_full(outfd, &r, sizeof(r)) < 0) exit(50 + tag);
    exit(0);
}

static uint64
absdiff(uint64 a, uint64 b)
{
    return a > b ? a - b : b - a;
}

int
main(void)
{
    int gate[2], out[2];
    if (pipe(gate) < 0 || pipe(out) < 0) fail("pipe");

    uint64 start_at = u_uptime() + 8;
    uint64 deadline = start_at + 140;
    int tickets[3] = {100, 50, 250};
    int pids[3];

    for (int i = 0; i < 3; i++) {
        int pid = fork();
        if (pid < 0) fail("fork");
        if (pid == 0) {
            close(gate[1]);
            close(out[0]);
            worker(i, tickets[i], gate[0], out[1], start_at, deadline);
        }
        pids[i] = pid;
    }

    close(gate[0]);
    close(out[1]);
    char token = 'x';
    for (int i = 0; i < 3; i++)
        if (write(gate[1], &token, 1) != 1) fail("release gate");
    close(gate[1]);

    uint64 d[3] = {0, 0, 0};
    for (int i = 0; i < 3; i++) {
        struct report r;
        if (read_full(out[0], &r, sizeof(r)) < 0) fail("read report");
        if (r.tag < 0 || r.tag >= 3) fail("bad report tag");
        d[r.tag] = r.delta;
    }
    close(out[0]);
    for (int i = 0; i < 3; i++)
        if (wait(0) < 0) fail("wait");

    printf("stride_share dispatches: A100=%l B50=%l C250=%l\n", d[0], d[1], d[2]);
    if (d[1] < 5) fail("measurement window too short");
    if (!(d[2] > d[0] && d[0] > d[1])) fail("share ordering");

    /* Expected A:B:C = 2:1:5.  Allow boundary/timer noise but not RR-like 1:1:1. */
    if (absdiff(d[0], 2 * d[1]) > d[1] / 2 + 4) fail("A:B proportionality");
    if (absdiff(d[2], 5 * d[1]) > d[1] + 8) fail("C:B proportionality");

    (void)pids;
    printf("STRIDE_SHARE: PASS\n");
    exit(0);
}
