/* Protected Lab 3 measurement helper. Do not modify this file. */
#include "ulib.h"

static volatile int sink;

int
main(int argc, char **argv)
{
    int n = 500000;
    if (argc == 2) {
        n = atoi(argv[1]);
        if (n <= 0) {
            fprintf(2, "usage: usibench [positive-iterations]\n");
            exit(1);
        }
    } else if (argc != 1) {
        fprintf(2, "usage: usibench [positive-iterations]\n");
        exit(1);
    }

    unsigned long t0 = (unsigned long)uptime();
    for (int i = 0; i < n; i++)
        sink ^= getpid();
    unsigned long t1 = (unsigned long)uptime();

    unsigned long t2 = (unsigned long)uptime();
    for (int i = 0; i < n; i++)
        sink ^= u_getpid();
    unsigned long t3 = (unsigned long)uptime();

    printf("usibench iterations=%d getpid_ticks=%d u_getpid_ticks=%d sink=%d\n",
           n, (int)(t1 - t0), (int)(t3 - t2), sink);
    exit(0);
}
