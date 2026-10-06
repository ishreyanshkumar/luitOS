/* Public functional test for CS3106L Lab 4.
 * Do not modify this file for submission: the official grader uses its own
 * clean copy.  Each risky test runs in a child so one bad page fault does not
 * prevent the remaining diagnostics from being printed. */
#include "ulib.h"

#define PGSIZE 4096UL
#define PGDOWN(a) ((uint64)(a) & ~(PGSIZE - 1))

static int failures;

typedef int (*testfn)(void);

static void
result(const char *name, int ok)
{
    printf("[%s] %s\n", ok ? "PASS" : "FAIL", name);
    if (!ok)
        failures++;
}

static int
run_child(testfn fn)
{
    int pid = fork();
    if (pid < 0)
        return 0;
    if (pid == 0)
        exit(fn() ? 0 : 1);

    int st = -99;
    int got = wait(&st);
    return got == pid && st == 0;
}

static int
lazy_reservation_child(void)
{
    int before = freepages();
    char *p = sbrk(6 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;
    int after = freepages();

    /* A reservation alone must not consume six physical data pages. */
    int ok = (after == before);
    if (sbrk(-6 * (int)PGSIZE) == (char *)-1)
        ok = 0;
    return ok;
}

static int
fault_materialization_child(void)
{
    char *p = sbrk(4 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;

    int reserved = freepages();

    /* The first read of a new heap page must observe zero. */
    volatile unsigned char z = (unsigned char)p[2 * PGSIZE + 37];
    if (z != 0)
        return 0;

    p[0] = 'A';
    p[3 * PGSIZE + 11] = 'Z';
    if (p[0] != 'A' || p[3 * PGSIZE + 11] != 'Z')
        return 0;

    /* Three distinct pages were touched. At least one new physical page must
     * therefore have appeared after the reservation point. */
    int touched = freepages();
    return touched < reserved;
}

static int
sparse_child(void)
{
    int before = freepages();
    char *p = sbrk(16 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;
    int reserved = freepages();
    if (reserved != before)
        return 0;

    p[0] = 1;
    int one = freepages();
    p[15 * PGSIZE] = 2;
    int two = freepages();

    return one < reserved && two < one && p[0] == 1 && p[15 * PGSIZE] == 2;
}

static int
expect_fault_beyond_break(void)
{
    int pid = fork();
    if (pid < 0)
        return 0;
    if (pid == 0) {
        char *p = sbrk((int)PGSIZE);
        if (p == (char *)-1)
            exit(2);
        volatile char *bad = p + PGSIZE;     /* exactly at the new break */
        *bad = 7;
        exit(3);                              /* reaching here is a failure */
    }
    int st = 0;
    int got = wait(&st);
    return got == pid && st == -1;
}

static int
expect_guard_fault(void)
{
    int pid = fork();
    if (pid < 0)
        return 0;
    if (pid == 0) {
        uint64 sp;
        asm volatile("mv %0, sp" : "=r"(sp));
        volatile char *guard = (volatile char *)(PGDOWN(sp) - PGSIZE);
        volatile char c = *guard;
        (void)c;
        exit(4);                              /* guard access must not return */
    }
    int st = 0;
    int got = wait(&st);
    return got == pid && st == -1;
}

static int
copyout_cross_page_child(void)
{
    const char data[] = "abcdefghijklmnop";
    unlink("l4_src");
    int fd = open("l4_src", O_CREATE | O_WRONLY);
    if (fd < 0)
        return 0;
    if (write(fd, data, 16) != 16) {
        close(fd);
        return 0;
    }
    close(fd);

    char *p = sbrk(2 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;
    char *dst = p + PGSIZE - 8;               /* crosses two lazy pages */

    fd = open("l4_src", O_RDONLY);
    if (fd < 0)
        return 0;
    int n = read(fd, dst, 16);
    close(fd);
    unlink("l4_src");
    if (n != 16)
        return 0;
    for (int i = 0; i < 16; i++)
        if (dst[i] != data[i])
            return 0;
    return 1;
}

static int
copyin_zero_page_child(void)
{
    unlink("l4_zero");
    char *p = sbrk((int)PGSIZE);
    if (p == (char *)-1)
        return 0;

    int fd = open("l4_zero", O_CREATE | O_WRONLY);
    if (fd < 0)
        return 0;
    int before = freepages();
    int n = write(fd, p, 64);                  /* source has never been touched */
    int after = freepages();
    close(fd);
    if (n != 64 || after >= before)
        return 0;

    char buf[64];
    memset(buf, 0x5a, sizeof(buf));
    fd = open("l4_zero", O_RDONLY);
    if (fd < 0)
        return 0;
    n = read(fd, buf, sizeof(buf));
    close(fd);
    unlink("l4_zero");
    if (n != (int)sizeof(buf))
        return 0;
    for (int i = 0; i < (int)sizeof(buf); i++)
        if (buf[i] != 0)
            return 0;
    return 1;
}

static int
copyinstr_lazy_child(void)
{
    char *path = sbrk((int)PGSIZE);
    if (path == (char *)-1)
        return 0;

    int before = freepages();
    /* A fresh lazy page is logically zero-filled. In this Luit checkpoint an
     * empty relative path denotes the current directory, so chdir("") is a
     * convenient way to exercise copyinstr() without first touching `path`. */
    int r = chdir(path);
    int after = freepages();
    return r == 0 && after < before;
}

static int
shrink_holes_child(void)
{
    char *p = sbrk(4 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;

    p[0] = 11;
    p[2 * PGSIZE] = 22;                       /* pages 1 and 3 remain holes */
    int before = freepages();
    if (sbrk(-4 * (int)PGSIZE) == (char *)-1)
        return 0;
    int after = freepages();

    /* At least the two materialized data pages must have been returned. */
    if (after < before + 2)
        return 0;

    /* The heap cannot shrink below the checkpoint-supplied heap base. */
    if (sbrk(-(int)PGSIZE) != (char *)-1)
        return 0;
    return 1;
}

static int
shrink_regrow_zero_child(void)
{
    char *p = sbrk((int)PGSIZE);
    if (p == (char *)-1)
        return 0;
    p[0] = 0x55;
    p[PGSIZE - 1] = 0x33;

    if (sbrk(-(int)PGSIZE) == (char *)-1)
        return 0;
    char *q = sbrk((int)PGSIZE);
    if (q != p)
        return 0;

    /* The old physical page must not remain attached to the regrown range. */
    return q[0] == 0 && q[PGSIZE - 1] == 0;
}

static int
fork_holes_child(void)
{
    char *p = sbrk(3 * (int)PGSIZE);
    if (p == (char *)-1)
        return 0;
    p[0] = 17;
    p[2 * PGSIZE] = 29;
    /* Middle page deliberately remains unmapped at fork(). */

    int pid = fork();
    if (pid < 0)
        return 0;
    if (pid == 0) {
        if (p[0] != 17 || p[2 * PGSIZE] != 29)
            exit(2);
        if (p[PGSIZE] != 0)                    /* child materializes its hole */
            exit(3);
        p[PGSIZE] = 0x5a;
        exit(0);
    }

    int st = -99;
    if (wait(&st) != pid || st != 0)
        return 0;

    /* Parent's corresponding hole must still be independent and zero-filled. */
    return p[PGSIZE] == 0 && p[0] == 17 && p[2 * PGSIZE] == 29;
}

int
main(void)
{
    printf("=== Lab 4 public lazy-memory test ===\n");

    result("sbrk reserves virtual memory without eager data pages",
           run_child(lazy_reservation_child));
    result("first user load/store materializes zero-filled pages",
           run_child(fault_materialization_child));
    result("sparse heap touches allocate only on demand",
           run_child(sparse_child));
    result("address at or beyond the process break is rejected",
           expect_fault_beyond_break());
    result("stack guard page remains protected",
           expect_guard_fault());
    result("kernel copyout materializes a cross-page lazy destination",
           run_child(copyout_cross_page_child));
    result("kernel copyin reads an untouched lazy page as zeros",
           run_child(copyin_zero_page_child));
    result("kernel copyinstr can read a valid untouched lazy page",
           run_child(copyinstr_lazy_child));
    result("shrinking frees mapped pages and tolerates lazy holes",
           run_child(shrink_holes_child));
    result("shrink then regrow returns fresh zero-filled memory",
           run_child(shrink_regrow_zero_child));
    result("fork preserves lazy holes and process isolation",
           run_child(fork_holes_child));

    if (failures == 0) {
        printf("LAB4: PASS\n");
        exit(0);
    }

    printf("LAB4: FAIL (%d check(s))\n", failures);
    exit(1);
}
