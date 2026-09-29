/* Protected Lab 3 helper: proves that exec() keeps USYSINFO_VA mapped. */
#include "ulib.h"

int
main(void)
{
    struct usysinfo s;
    int pid = getpid();
    if (u_snapshot(&s) < 0 || s.pid != pid || u_getpid() != pid) {
        printf("USIEXEC: FAIL\n");
        exit(1);
    }
    printf("USIEXEC: PASS\n");
    exit(0);
}
