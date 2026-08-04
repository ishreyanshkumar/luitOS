/* Lab 1 starter: sleep
 * Complete only the marked TODO sections. You may add helper functions in
 * this file, but do not modify the kernel or the generated syscall files. */
#include "ulib.h"
#include <limits.h>

/* Parse one non-negative decimal integer that fits in a signed int.
 * Return 0 on success and store the result in *ticks; return -1 otherwise. */
static int
parse_ticks(const char *text, long long *ticks)
{
    /* TODO-BEGIN S1: validate the complete string and convert safely. */
    if(text[0] == '\0') return -1;

    long long result = 0;
    for(int i=0;text[i]!='\0';i++){
        if(text[i]<'0' || text[i]>'9') return -1;
        result = result * 10 + (text[i] - '0');
    }
    *ticks = result;
    return 0;
    /* TODO-END S1 */
}

int
main(int argc, char *argv[])
{
    long long ticks = 0;

    (void)parse_ticks;  /* keeps the compilable starter warning-free */

    if (argc != 2) {
        fprintf(2, "sleep: usage: sleep ticks\n");
        exit(1);
    }

    /* TODO-BEGIN S2: call parse_ticks() and reject invalid input. */
    if(parse_ticks(argv[1],&ticks) == -1){
        fprintf(2, "sleep: system call failed\n");
        exit(1);
    }
    /* TODO-END S2 */

    /* TODO-BEGIN S3: invoke sleep(ticks), check failure, and exit correctly. */
    if (sleep(ticks) < 0) {
        fprintf(2, "sleep: ticks must be a non-negative decimal integer\n");
        exit(1);
    }

    if (ticks > INT_MAX) {
            fprintf(2, "sleep: ticks must be a non-negative decimal integer\n");
            exit(1);
    }
    exit(0);
    /* TODO-END S3 */
}
