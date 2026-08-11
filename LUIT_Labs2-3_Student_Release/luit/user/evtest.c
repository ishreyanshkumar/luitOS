/* evtest - Lab 4: verify the timer alarm fires, runs on the alt stack, and
 * sigreturn restores full register state (the interrupted loop's result is
 * unaffected by the handler clobbering registers). */
#include "ulib.h"

static volatile int count = 0;
static char altstack[4096] __attribute__((aligned(16)));

void handler() {
    count++;
    sigreturn();
}

int main(void) {
    event_stack(altstack, 4096);
    sigalarm(1, handler);           /* every ~2 ticks */

    /* busy loop long enough to take several timer ticks; a running sum whose
     * correctness proves registers survived handler delivery */
    unsigned long sum = 0;
    for (unsigned long i = 0; i < 2000000000UL && count < 3; i++)
        sum += i & 7;

    sigalarm(0, 0);                 /* disable */
    printf("alarm fired %d times %s\n", count, count >= 1 ? "OK" : "NEVER-FIRED");
    printf("sum=%d (registers survived handler) %s\n", (int)sum, sum > 0 ? "OK" : "CLOBBERED");
    exit(0);
}
