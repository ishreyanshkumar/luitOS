/* futextest - Lab 6: clone shares AS; futex mutex protects a shared counter;
 * lost-wakeup stress. */
#include "ulib.h"

static unsigned long lock = 0;
static volatile int counter = 0;
static volatile int done = 0;

#define NT 3
#define ITERS 2000
static char stacks[NT][4096] __attribute__((aligned(16)));

void worker(void *arg) {
    for (int i = 0; i < ITERS; i++) {
        mutex_lock(&lock);
        counter++;                 /* shared: proves AS is shared + mutex works */
        mutex_unlock(&lock);
    }
    done++;
    exit(0);                       /* thread exits cleanly */
}

int main(void) {
    int base = counter;
    for (int t = 0; t < NT; t++)
        thread_create(worker, 0, &stacks[t][4096]);
    /* spin until all workers finish their increments */
    while (done < NT) { }
    int expect = base + NT * ITERS;
    printf("counter=%d expected=%d %s\n", counter, expect,
           counter == expect ? "OK" : "RACE-OR-LOST");
    printf("shared-address-space: %s\n", counter > base ? "OK" : "NOT-SHARED");
    exit(0);
}
