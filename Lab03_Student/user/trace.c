/* trace <command> [args] - run a command with syscall tracing, print events. */
#include "ulib.h"
#define MAXEV 512
static const char *names[] = {
    [1]="fork",[2]="exit",[3]="wait",[4]="pipe",[5]="read",[6]="kill",
    [7]="exec",[8]="fstat",[9]="chdir",[10]="dup",[11]="getpid",[12]="sbrk",
    [13]="sleep",[14]="uptime",[15]="open",[16]="write",[18]="unlink",
    [19]="link",[20]="mkdir",[21]="close",[22]="freepages",[23]="procstat",
    [24]="tracectl",[25]="traceread",
};
static const char *nm(int n){ return (n>0 && n<26 && names[n]) ? names[n] : "?"; }
int main(int argc, char *argv[]) {
    if (argc < 2) { fprintf(2, "usage: trace command [args]\n"); exit(1); }
    tracectl(1, 0);
    int pid = fork();
    if (pid < 0) { fprintf(2, "trace: fork failed\n"); exit(1); }
    if (pid == 0) { exec(argv[1], argv+1); fprintf(2,"trace: exec failed\n"); exit(1); }
    wait(0);
    tracectl(0, 0);
    static struct trace_event ev[MAXEV];
    int n = traceread(ev, MAXEV);
    if (n < 0) { fprintf(2, "trace: traceread failed\n"); exit(1); }
    printf("--- %d trace events ---\n", n);
    for (int i = 0; i < n; i++) {
        if (ev[i].num == -1) { printf("[hart %d] DROPPED %d events (ring overflow)\n", ev[i].hart, (int)ev[i].arg0); continue; }
        printf("pid %d hart %d  %s(arg0=%d) = %d\n", ev[i].pid, ev[i].hart, nm(ev[i].num), (int)ev[i].arg0, (int)ev[i].ret);
    }
    exit(0);
}
