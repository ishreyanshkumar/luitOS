#include "ulib.h"

#define PF_UNMAPPED_VA 0x40000000UL
#define PGSIZE_U       4096UL

static void usage(void)
{
    printf("usage: pfdemo load|store|guard|exec|readpath|eager\n");
    exit(1);
}

static void demo_load(void)
{
    volatile uint64 *p = (volatile uint64 *)PF_UNMAPPED_VA;
    printf("pfdemo: about to LOAD from unmapped user VA %p\n", (uint64)p);
    uint64 x = *p;
    printf("pfdemo: unexpected load success: %p\n", x);
}

static void demo_store(void)
{
    volatile uint32 *p = (volatile uint32 *)USYSINFO_VA;
    printf("pfdemo: about to STORE to read-only USYSINFO VA %p\n", (uint64)p);
    *p = 0x12345678U;
    printf("pfdemo: unexpected store success\n");
}

static void demo_guard(void)
{
    /* Immediately after exec, p->sz is the top of the initial stack page.
     * pfdemo does not allocate heap memory before this point, so sbrk(0)
     * gives that top. Luit exec places one unmapped guard page immediately
     * below the stack page. */
    char *top = sbrk(0);
    volatile uint8 *guard = (volatile uint8 *)(top - 2 * PGSIZE_U);
    printf("pfdemo: current p->sz/top is approximately %p\n", (uint64)top);
    printf("pfdemo: about to STORE into guard page at %p\n", (uint64)guard);
    *guard = 0x5a;
    printf("pfdemo: unexpected guard-page store success\n");
}

static void demo_exec(void)
{
    void (*fn)(void) = (void (*)(void))PF_UNMAPPED_VA;
    printf("pfdemo: about to FETCH/EXECUTE at unmapped user VA %p\n",
           (uint64)PF_UNMAPPED_VA);
    fn();
    printf("pfdemo: unexpected execute success\n");
}

static void demo_readpath(void)
{
    char buf[64];
    int fd = open("/pfdemo", O_RDONLY);
    if (fd < 0) {
        printf("pfdemo: open /pfdemo failed\n");
        exit(1);
    }
    printf("pfdemo: read destination user buffer is %p\n", (uint64)buf);
    printf("pfdemo: now call read(); use GDB breakpoints on readi and copyout\n");
    int n = read(fd, buf, sizeof(buf));
    printf("pfdemo: read returned %d\n", n);
    close(fd);
}

static void demo_eager(void)
{
    int before = freepages();
    char *old = sbrk(PGSIZE_U);
    int after_sbrk = freepages();
    if ((long)old == -1) {
        printf("pfdemo: sbrk failed\n");
        exit(1);
    }
    printf("pfdemo: sbrk returned %p\n", (uint64)old);
    printf("pfdemo: free pages before=%d after-sbrk=%d\n", before, after_sbrk);
    printf("pfdemo: touching new page at %p; baseline Luit should NOT page-fault\n",
           (uint64)old);
    old[0] = 'L';
    old[PGSIZE_U - 1] = 'T';
    printf("pfdemo: touch succeeded; free pages now=%d\n", freepages());
}

int main(int argc, char **argv)
{
    if (argc != 2) usage();

    if (strcmp(argv[1], "load") == 0) demo_load();
    else if (strcmp(argv[1], "store") == 0) demo_store();
    else if (strcmp(argv[1], "guard") == 0) demo_guard();
    else if (strcmp(argv[1], "exec") == 0) demo_exec();
    else if (strcmp(argv[1], "readpath") == 0) demo_readpath();
    else if (strcmp(argv[1], "eager") == 0) demo_eager();
    else usage();

    exit(0);
}
