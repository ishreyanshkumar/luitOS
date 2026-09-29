/* Stress: many concurrent children across all harts. Run with -smp 4. */
#include "ulib.h"
#define N 30
int main(void)
{
    printf("forktest: spawning %d children\n", N);
    int n;
    for (n = 0; n < N; n++) {
        int pid = fork();
        if (pid < 0) break;
        if (pid == 0) {
            volatile long x = 0;
            for (long i = 0; i < 200000L; i++) x += i;
            exit(0);
        }
    }
    for (int i = 0; i < n; i++) wait(0);
    printf("forktest: %d children completed, %d free pages\n", n, freepages());
    printf("forktest: OK\n");
    exit(0);
}
