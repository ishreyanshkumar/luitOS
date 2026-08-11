/* alloctest - Lab 8: drive concurrent allocation from several processes, read
 * per-hart contention stats, and check the conservation invariant. (Students
 * extend this with 2 competing allocator policies; the baseline + instrumentation
 * + audit are provided.) */
#include "ulib.h"

int main(void) {
    int audit0 = alloc_audit();
    printf("audit before: %d %s\n", audit0, audit0==0?"OK":"VIOLATION");

    /* spawn 4 children that each churn memory, forcing lock contention */
    for (int c = 0; c < 4; c++) {
        int pid = fork();
        if (pid == 0) {
            for (int i = 0; i < 200; i++) {
                char *p = sbrk(4096);      /* allocate */
                p[0] = 1;
                sbrk(-4096);               /* free */
            }
            exit(0);
        }
    }
    for (int c = 0; c < 4; c++) wait(0);

    struct allocstat st;
    alloc_stats(&st);
    unsigned long total_acq = 0;
    int harts_active = 0;
    for (int h = 0; h < 8; h++) {
        total_acq += st.acquires[h];
        if (st.acquires[h] > 0) harts_active++;
    }
    printf("lock acquisitions total=%d across %d harts\n", (int)total_acq, harts_active);
    printf("free=%d total=%d\n", st.nfree, st.total);

    int audit1 = alloc_audit();
    printf("audit after: %d %s\n", audit1, audit1==0?"OK":"VIOLATION");
    exit(0);
}
