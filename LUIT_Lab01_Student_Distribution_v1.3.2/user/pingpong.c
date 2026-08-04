/* Lab 1 starter: pingpong
 * Complete only the marked TODO sections. The communication protocol must
 * use two unidirectional pipes and must not use sleep() for ordering. */
#include "ulib.h"

static void
fail(const char *message)
{
    fprintf(2, "pingpong: %s\n", message);
    exit(1);
}

int
main(int argc, char *argv[])
{
    int p2c[2];
    int c2p[2];
    int pid;
    char token = 'P';
    char received = 0;

    (void)argv;

    if (argc != 1) {
        fprintf(2, "pingpong: usage: pingpong\n");
        exit(1);
    }

    /* TODO-BEGIN P1: create both pipes and handle partial setup safely. */
    p2c[0] = p2c[1] = c2p[0] = c2p[1] = -1;
    fail("TODO P1 is not implemented");
    /* TODO-END P1 */

    /* TODO-BEGIN P2: fork and handle fork failure. */
    pid = -1;
    fail("TODO P2 is not implemented");
    /* TODO-END P2 */

    if (pid == 0) {
        /* Child process.
         * Close unused ends, read and verify one byte, print the ping line,
         * return one byte, close retained ends, and exit successfully. */
        /* TODO-BEGIN P3: implement the child side of the protocol. */
        (void)p2c;
        (void)c2p;
        (void)token;
        (void)received;
        fail("TODO P3 is not implemented");
        /* TODO-END P3 */
    }

    /* Parent process.
     * Close unused ends, send one byte, read and verify the reply, print the
     * pong line, close retained ends, reap the child, and exit successfully. */
    /* TODO-BEGIN P4: implement the parent side of the protocol. */
    (void)p2c;
    (void)c2p;
    (void)token;
    (void)received;
    fail("TODO P4 is not implemented");
    /* TODO-END P4 */

    return 1;  /* unreachable because fail() calls exit() */
}
