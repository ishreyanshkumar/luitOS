/* vdemo - a classroom demonstration of virtualization.
 *
 * ONE command launches several processes, so the demonstration never depends
 * on how fast the instructor can type. Each child writes its own pid into a
 * global variable - a variable that lives at the SAME virtual address in
 * every process - and then prints that address and its private value.
 *
 *   usage:  vdemo [nprocs] [rounds]        (defaults: 3 processes, 6 rounds)
 *
 * The teaching point: every line shows the identical address, yet each
 * process reports a different value. The address is virtual; the physical
 * memory behind it is private. Meanwhile the interleaving of the lines shows
 * one CPU being time-sliced among them.
 */
#include "ulib.h"

/* A global lives at a FIXED virtual address, identical in every process -
 * yet each process gets its own private copy of it. */
int owned_by_me = 0;

int main(int argc, char *argv[])
{
    int nprocs = (argc > 1) ? atoi(argv[1]) : 3;
    int rounds = (argc > 2) ? atoi(argv[2]) : 6;

    if (nprocs < 1) nprocs = 1;
    if (nprocs > 8) nprocs = 8;      /* keep the screen readable */
    if (rounds < 1) rounds = 1;

    printf("\n=== virtualization demo: %d processes, one machine ===\n", nprocs);
    printf("watch the ADDRESS (identical everywhere) and the VALUE (private to each)\n\n");

    for (int i = 0; i < nprocs; i++) {
        int pid = fork();
        if (pid < 0) { printf("vdemo: fork failed\n"); exit(1); }

        if (pid == 0) {
            /* ---- child: believes it owns the machine ---- */
            int me = getpid();
            owned_by_me = me;        /* same address in every child */

            for (int r = 0; r < rounds; r++) {
                printf("pid %d: &owned_by_me = %p   value = %d\n",
                       me, &owned_by_me, owned_by_me);
                owned_by_me += 1000; /* only THIS process's copy changes */
                sleep(15);           /* yield, so the others get the CPU */
            }
            printf("pid %d: finished with %d  (nobody else could touch it)\n",
                   me, owned_by_me);
            exit(0);
        }
        /* parent continues, launching the next one */
    }

    for (int i = 0; i < nprocs; i++)
        wait(0);

    printf("\n=== all %d processes ran on ONE machine ===\n", nprocs);
    printf("same address everywhere, different value each: memory is virtual and private\n");
    printf("their lines interleaved: the CPU was time-sliced among them\n\n");
    exit(0);
}
