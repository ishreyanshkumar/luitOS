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
    if (pipe(p2c) < 0) {
        fail("pipe p2c failed");
    }
    if (pipe(c2p) < 0) {
        close(p2c[0]);
        close(p2c[1]);
        fail("pipe c2p failed");
    }
    /* TODO-END P1 */

    /* TODO-BEGIN P2: fork and handle fork failure. */
    pid = fork();
    if (pid < 0) {
        close(p2c[0]);
        close(p2c[1]);
        close(c2p[0]);
        close(c2p[1]);
        fail("fork failed");
    }
    /* TODO-END P2 */

    if (pid == 0) {
        /* Child process.
         * Close unused ends, read and verify one byte, print the ping line,
         * return one byte, close retained ends, and exit successfully. */
        /* TODO-BEGIN P3: implement the child side of the protocol. */
        close(p2c[1]); // Close write end of parent-to-child
        close(c2p[0]); // Close read end of child-to-parent
        
        if (read(p2c[0], &received, 1) != 1) {
            fail("child read failed");
        }

        // Validate the byte!
        if (received != token) {
            fail("child received incorrect byte");
        }
        
        fprintf(1, "%d: received ping\n", getpid());
        
        if (write(c2p[1], &token, 1) != 1) {
            fail("child write failed");
        }
        
        close(p2c[0]);
        close(c2p[1]);
        exit(0);
        /* TODO-END P3 */
    }

    /* Parent process.
     * Close unused ends, send one byte, read and verify the reply, print the
     * pong line, close retained ends, reap the child, and exit successfully. */
    /* TODO-BEGIN P4: implement the parent side of the protocol. */
    close(p2c[0]); // Close read end of parent-to-child
    close(c2p[1]); // Close write end of child-to-parent
    
    if (write(p2c[1], &token, 1) != 1) {
        fail("parent write failed");
    }
    
    if (read(c2p[0], &received, 1) != 1) {
        fail("parent read failed");
    }
    
    // Validate the byte!
    if (received != token) {
        fail("parent received incorrect byte");
    }
    
    fprintf(1, "%d: received pong\n", getpid());
    
    close(p2c[1]);
    close(c2p[0]);
    
    wait(0); // Reap the child
    exit(0);
    /* TODO-END P4 */

    return 1;  /* unreachable because fail() calls exit() */
}
