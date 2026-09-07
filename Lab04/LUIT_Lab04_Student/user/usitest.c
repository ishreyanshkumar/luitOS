/* Protected public test for Lab 3. Do not modify this file. */
#include "ulib.h"

static int failures;

static void
result(const char *name, int ok)
{
    printf("[%s] %s\n", ok ? "PASS" : "FAIL", name);
    if (!ok)
        failures++;
}

static unsigned long
absdiff(unsigned long a, unsigned long b)
{
    return a > b ? a - b : b - a;
}

static void
basic_tests(void)
{
    volatile struct usysinfo *raw = (volatile struct usysinfo *)USYSINFO_VA;
    struct usysinfo s;

    result("version", raw->version == USYSINFO_VERSION);
    result("null snapshot rejected", u_snapshot(0) == -1);
    result("snapshot returns", u_snapshot(&s) == 0);
    if (u_snapshot(&s) == 0) {
        result("snapshot pid", s.pid == getpid());
        result("seq stable/even", (s.seq & 1U) == 0 && (raw->seq & 1U) == 0);
        result("scheduler generation invariant",
               (uint32)s.ctxsw_count == s.state_gen);
    }

    int fastpid = u_getpid();
    int syspid = getpid();
    result("u_getpid matches", fastpid == syspid);

    unsigned long fastup = u_uptime();
    unsigned long sysup = (unsigned long)uptime();
    result("u_uptime close", absdiff(fastup, sysup) <= 3);
}

static void
no_ecall_fast_path(void)
{
    struct usysinfo a, b;
    int ok = u_snapshot(&a) == 0;
    int pid = 0;
    if (ok) {
        pid = a.pid;
        for (int i = 0; i < 512; i++)
            if (u_getpid() != pid)
                ok = 0;
        if (u_snapshot(&b) < 0)
            ok = 0;
        else if (b.syscall_count != a.syscall_count)
            ok = 0;
    }
    result("fast getpid executes no syscall", ok);

    ok = u_snapshot(&a) == 0;
    if (ok) {
        unsigned long last = a.ticks;
        for (int i = 0; i < 512; i++) {
            unsigned long now = u_uptime();
            if (now < last)
                ok = 0;
            last = now;
        }
        if (u_snapshot(&b) < 0)
            ok = 0;
        else if (b.syscall_count != a.syscall_count)
            ok = 0;
    }
    result("fast uptime executes no syscall", ok);

    ok = u_snapshot(&a) == 0;
    if (ok) {
        for (int i = 0; i < 8; i++)
            (void)getpid();
        if (u_snapshot(&b) < 0)
            ok = 0;
        else if (b.syscall_count < a.syscall_count + 8)
            ok = 0;
    }
    result("real syscalls are counted", ok);
}

static void
consistency_stress(void)
{
    struct usysinfo s;
    unsigned long last_ticks = 0;
    unsigned long last_sys = 0;
    unsigned long last_ctx = 0;
    int mypid = getpid();
    int torn = 0;

    for (int i = 0; i < 100000; i++) {
        if (u_snapshot(&s) < 0) {
            torn++;
            break;
        }
        if (s.pid != mypid)
            torn++;
        if (s.ticks < last_ticks || s.syscall_count < last_sys ||
            s.ctxsw_count < last_ctx)
            torn++;
        if ((uint32)s.ctxsw_count != s.state_gen)
            torn++;
        if (s.seq & 1U)
            torn++;

        last_ticks = s.ticks;
        last_sys = s.syscall_count;
        last_ctx = s.ctxsw_count;

        /* These calls create publication points while the long reader loop
         * continues to be preemptible by timer interrupts. */
        if ((i % 4096) == 0)
            (void)getpid();
    }
    printf("consistency: snapshots=100000 torn=%d\n", torn);
    result("consistent multi-field snapshots", torn == 0);
}

static void
protection_test(void)
{
    int pid = fork();
    if (pid < 0) {
        result("read-only mapping", 0);
        return;
    }
    if (pid == 0) {
        volatile struct usysinfo *raw = (volatile struct usysinfo *)USYSINFO_VA;
        raw->pid = 0x12345678;   /* must take a user store page fault */
        exit(77);                /* reaching this means protection failed */
    }

    int status = 0;
    int got = wait(&status);
    result("read-only mapping", got == pid && status == -1);
    result("kernel survives bad user write", getpid() > 0);
}

static void
isolation_test(void)
{
    int parent = getpid();
    int pid = fork();
    if (pid < 0) {
        result("per-process page", 0);
        return;
    }
    if (pid == 0) {
        struct usysinfo s;
        int me = getpid();
        int ok = u_snapshot(&s) == 0 && s.pid == me && me != parent;
        exit(ok ? 0 : 1);
    }
    int status = -99;
    int got = wait(&status);
    struct usysinfo s;
    int parent_ok = u_snapshot(&s) == 0 && s.pid == parent;
    result("per-process page", got == pid && status == 0 && parent_ok);
}

static void
exec_test(void)
{
    int pid = fork();
    if (pid < 0) {
        result("exec remaps info page", 0);
        return;
    }
    if (pid == 0) {
        char *argv[] = { "usiexec", 0 };
        exec("usiexec", argv);
        exit(2);
    }
    int status = -99;
    int got = wait(&status);
    result("exec remaps info page", got == pid && status == 0);
}

int
main(void)
{
    printf("=== Lab 3 public usysinfo test ===\n");
    basic_tests();
    no_ecall_fast_path();
    consistency_stress();
    protection_test();
    isolation_test();
    exec_test();

    if (failures == 0) {
        printf("LAB3: PASS\n");
        exit(0);
    }
    printf("LAB3: FAIL (%d check(s))\n", failures);
    exit(1);
}
