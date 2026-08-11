/* The graded test suite. TAs: run this at every milestone. Each test targets
 * a specific property from the lab spec. If a student's kernel passes all of
 * these AND survives the adversarial tests below, it is a real kernel. */
#include "ulib.h"

static int fails = 0;
static void ok(const char *n)  { printf("  [ OK ] %s\n", n); }
static void bad(const char *n) { printf("  [FAIL] %s\n", n); fails++; }

/* The kernel must survive hostile user pointers, not panic. */
static void test_badptr(void)
{
    /* a kernel address */
    if (write(1, (void *)0x80200000UL, 4) != -1) { bad("write(kernel addr) rejected"); return; }
    /* a null pointer */
    if (write(1, (void *)0, 4) != -1)            { bad("write(null) rejected"); return; }
    /* an unmapped user address */
    if (write(1, (void *)0x7f000000UL, 4) != -1) { bad("write(unmapped) rejected"); return; }
    ok("hostile user pointers rejected (kernel still alive)");
}

/* A bad syscall number must return -1, not take the kernel down. */
static void test_badsyscall(void)
{
    long r;
    asm volatile("li a7, 999; ecall; mv %0, a0" : "=r"(r) :: "a0","a7");
    if (r != -1) { bad("bad syscall number returns -1"); return; }
    ok("bad syscall number rejected");
}

/* fork isolation - child writes must NOT be visible to the parent. This
 * property must KEEP passing after Lab 5 turns eager copy into COW: it is
 * the regression test that says your COW fork is still a correct fork. */
static void test_fork_isolation(void)
{
    static char page[4096];
    for (int i = 0; i < 4096; i++) page[i] = 'A';

    int pid = fork();
    if (pid < 0) { bad("fork-iso: fork"); return; }
    if (pid == 0) {
        for (int i = 0; i < 4096; i++) page[i] = 'B';
        for (int i = 0; i < 4096; i++)
            if (page[i] != 'B') exit(1);
        exit(0);
    }
    int st = 0;
    wait(&st);
    if (st != 0) { bad("fork-iso: child could not write its own copy"); return; }
    for (int i = 0; i < 4096; i++) {
        if (page[i] != 'A') { bad("fork-iso: CHILD CORRUPTED THE PARENT"); return; }
    }
    ok("fork isolation: parent and child memory are independent");
}

/* L11: the killer test. Fork many children; every physical page must come back.
 * A refcount leak shows up here and nowhere else. */
static void test_no_leak(void)
{
    int before = freepages();
    for (int i = 0; i < 20; i++) {
        int pid = fork();
        if (pid < 0) { bad("leak: fork failed"); return; }
        if (pid == 0) {
            static volatile char buf[8192];
            for (int j = 0; j < 8192; j++) buf[j] = (char)j;   /* dirty the pages */
            exit(buf[100] == 100 ? 0 : 1);
        }
        wait(0);
    }
    int after = freepages();
    if (after != before) {
        printf("  free pages: %d before, %d after (leaked %d)\n",
               before, after, before - after);
        bad("no page leak across 20 fork/exit cycles");
        return;
    }
    ok("no page leak across 20 fork/exit cycles (refcounts are correct)");
}

/* L7/L8: preemption. Two CPU-bound children with no yields must both finish. */
static void test_preemption(void)
{
    int a = fork();
    if (a == 0) { volatile long x = 0; for (long i = 0; i < 8000000L; i++) x += i; exit(7); }
    int b = fork();
    if (b == 0) { volatile long x = 0; for (long i = 0; i < 8000000L; i++) x += i; exit(9); }
    int s1 = 0, s2 = 0;
    wait(&s1); wait(&s2);
    if ((s1 == 7 || s1 == 9) && (s2 == 7 || s2 == 9) && s1 != s2)
        ok("preemptive scheduling: both CPU-bound children completed");
    else
        bad("preemptive scheduling");
}

/* L12: sbrk grows the heap and the memory is actually usable. */
static void test_sbrk(void)
{
    char *p = sbrk(8192);
    if (p == (char *)-1) { bad("sbrk"); return; }
    for (int i = 0; i < 8192; i++) p[i] = (char)i;
    for (int i = 0; i < 8192; i++)
        if (p[i] != (char)i) { bad("sbrk memory not usable"); return; }
    ok("sbrk: heap grows and is writable");
}

/* exit status propagates through wait(). */
static void test_exit_status(void)
{
    int pid = fork();
    if (pid == 0) exit(42);
    int st = 0;
    int w = wait(&st);
    if (w == pid && st == 42) ok("wait() returns the child's exit status");
    else bad("wait()/exit() status");
}


/* ---- file descriptor / pipe / LuitFS tests ---- */

static void test_pipe_basic(void)
{
    int p[2];
    if (pipe(p) < 0) { bad("pipe: create"); return; }
    int pid = fork();
    if (pid == 0) {
        close(p[0]);
        write(p[1], "brahmaputra", 11);
        close(p[1]);
        exit(0);
    }
    close(p[1]);                      /* or the read below never sees EOF */
    char buf[32];
    int n = 0, r;
    while ((r = read(p[0], buf + n, sizeof(buf) - n)) > 0) n += r;
    close(p[0]);
    wait(0);
    buf[n] = 0;
    if (n == 11 && strcmp(buf, "brahmaputra") == 0) ok("pipe: write/read/EOF");
    else bad("pipe: write/read/EOF");
}

static void test_pipe_eof(void)
{
    int p[2];
    if (pipe(p) < 0) { bad("pipe-eof: create"); return; }
    close(p[1]);                      /* no writers at all */
    char c;
    if (read(p[0], &c, 1) == 0) ok("pipe: read with no writers returns EOF");
    else bad("pipe: read with no writers returns EOF");
    close(p[0]);
}

static void test_file_rw(void)
{
    unlink("ut_f");
    int fd = open("ut_f", O_CREATE | O_WRONLY);
    if (fd < 0) { bad("fs: create"); return; }
    for (int i = 0; i < 10; i++)
        if (write(fd, "0123456789", 10) != 10) { bad("fs: write"); close(fd); return; }
    close(fd);

    fd = open("ut_f", O_RDONLY);
    if (fd < 0) { bad("fs: reopen"); return; }
    char buf[10];
    int total = 0, n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        for (int i = 0; i < n; i++)
            if (buf[i] != '0' + (total + i) % 10) { bad("fs: readback data"); close(fd); return; }
        total += n;
    }
    close(fd);
    if (total != 100) { bad("fs: readback size"); return; }

    struct stat st;
    if (stat("ut_f", &st) < 0 || st.size != 100) { bad("fs: stat size"); return; }
    if (unlink("ut_f") < 0) { bad("fs: unlink"); return; }
    if (open("ut_f", O_RDONLY) >= 0) { bad("fs: unlinked file still opens"); return; }
    ok("fs: create/write/read/stat/unlink");
}

static void test_bigfile(void)
{
    /* Cross the direct/indirect boundary: > NDIRECT KiB. */
    unlink("ut_big");
    int fd = open("ut_big", O_CREATE | O_RDWR);
    if (fd < 0) { bad("fs-big: create"); return; }
    static char blk[1024];
    for (int b = 0; b < 20; b++) {           /* 20 KiB > 12 direct blocks */
        memset(blk, 'a' + b, sizeof(blk));
        if (write(fd, blk, sizeof(blk)) != sizeof(blk)) { bad("fs-big: write"); close(fd); return; }
    }
    close(fd);
    fd = open("ut_big", O_RDONLY);
    for (int b = 0; b < 20; b++) {
        if (read(fd, blk, sizeof(blk)) != sizeof(blk)) { bad("fs-big: read"); close(fd); return; }
        for (int i = 0; i < 1024; i += 128)
            if (blk[i] != 'a' + b) { bad("fs-big: data across indirect boundary"); close(fd); return; }
    }
    close(fd);
    unlink("ut_big");
    ok("fs: file spans direct + indirect blocks");
}

static void test_dirs(void)
{
    unlink("ut_d/f"); unlink("ut_d");
    if (mkdir("ut_d") < 0) { bad("fs-dir: mkdir"); return; }
    int fd = open("ut_d/f", O_CREATE | O_WRONLY);
    if (fd < 0) { bad("fs-dir: create in subdir"); return; }
    write(fd, "x", 1);
    close(fd);
    if (chdir("ut_d") < 0) { bad("fs-dir: chdir"); return; }
    fd = open("f", O_RDONLY);                /* relative path */
    if (fd < 0) { bad("fs-dir: relative open"); chdir(".."); return; }
    close(fd);
    if (chdir("..") < 0) { bad("fs-dir: chdir .."); return; }
    if (unlink("ut_d") >= 0) { bad("fs-dir: unlinked non-empty dir!"); return; }
    unlink("ut_d/f");
    if (unlink("ut_d") < 0) { bad("fs-dir: rmdir empty"); return; }
    ok("fs: directories, relative paths, non-empty-dir protection");
}

static void test_link(void)
{
    unlink("ut_l1"); unlink("ut_l2");
    int fd = open("ut_l1", O_CREATE | O_WRONLY);
    write(fd, "shared", 6);
    close(fd);
    if (link("ut_l1", "ut_l2") < 0) { bad("fs-link: link"); return; }
    if (unlink("ut_l1") < 0) { bad("fs-link: unlink original"); return; }
    fd = open("ut_l2", O_RDONLY);            /* data must survive via link */
    char buf[8];
    int n = read(fd, buf, 6);
    close(fd);
    unlink("ut_l2");
    if (n == 6) ok("fs: hard link keeps data alive after unlink");
    else bad("fs: hard link keeps data alive after unlink");
}

static void test_shared_offset(void)
{
    /* fork shares ONE struct file => one offset. */
    unlink("ut_o");
    int fd = open("ut_o", O_CREATE | O_WRONLY);
    int pid = fork();
    if (pid == 0) { write(fd, "AA", 2); exit(0); }
    wait(0);
    write(fd, "BB", 2);
    close(fd);
    struct stat st;
    stat("ut_o", &st);
    unlink("ut_o");
    if (st.size == 4) ok("fd: fork shares the file offset");
    else bad("fd: fork shares the file offset");
}

static void test_dup_redirect(void)
{
    unlink("ut_r");
    int pid = fork();
    if (pid == 0) {
        close(1);
        if (open("ut_r", O_CREATE | O_WRONLY) != 1) exit(1);
        printf("redirected");         /* goes to the file via fd 1 */
        exit(0);
    }
    int st;
    wait(&st);
    if (st != 0) { bad("fd: redirect setup"); return; }
    int fd = open("ut_r", O_RDONLY);
    char buf[16];
    int n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    unlink("ut_r");
    buf[n < 0 ? 0 : n] = 0;
    if (n == 10 && strcmp(buf, "redirected") == 0)
        ok("fd: close+open redirection captures stdout");
    else bad("fd: close+open redirection captures stdout");
}

int main(void)
{
    printf("\n=== BrahmaputraOS usertests ===\n");
    test_exit_status();
    test_badsyscall();
    test_badptr();
    test_sbrk();
    test_preemption();
    test_fork_isolation();
    test_pipe_basic();
    test_pipe_eof();
    test_file_rw();
    test_bigfile();
    test_dirs();
    test_link();
    test_shared_offset();
    test_dup_redirect();
    test_no_leak();

    if (fails == 0) printf("=== ALL TESTS PASSED ===\n");
    else            printf("=== %d TEST(S) FAILED ===\n", fails);
    exit(fails);
}
