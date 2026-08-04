/* Lab 1 starter: sleep
 * Complete only the marked TODO sections. You may add helper functions in
 * this file, but do not modify the kernel or the generated syscall files. */
#include "ulib.h"

/* Parse one non-negative decimal integer that fits in a signed int.
 * Return 0 on success and store the result in *ticks; return -1 otherwise. */
static int
parse_ticks(const char *text, int *ticks)
{
    /* TODO-BEGIN S1: validate the complete string and convert safely. */
    (void)text;
    (void)ticks;
    return -1;
    /* TODO-END S1 */
}

int
main(int argc, char *argv[])
{
    int ticks = 0;

    (void)parse_ticks;  /* keeps the compilable starter warning-free */

    if (argc != 2) {
        fprintf(2, "sleep: usage: sleep ticks\n");
        exit(1);
    }

    /* TODO-BEGIN S2: call parse_ticks() and reject invalid input. */
    (void)argv;
    fprintf(2, "sleep: TODO S2 is not implemented\n");
    exit(1);
    /* TODO-END S2 */

    /* TODO-BEGIN S3: invoke sleep(ticks), check failure, and exit correctly. */
    (void)ticks;
    fprintf(2, "sleep: TODO S3 is not implemented\n");
    exit(1);
    /* TODO-END S3 */
}
