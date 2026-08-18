/* Lab 2: kernel tracing subsystem - per-hart event rings. */
#ifndef LUIT_TRACE_H
#define LUIT_TRACE_H
#define NTRACE 128
struct trace_event {
    int    pid; int hart; int num; long ret; uint64 ts; uint64 arg0;
};
#define TRACE_DISABLE 0
#define TRACE_ENABLE  1
void trace_init(void);
void trace_record(int num, long ret, uint64 arg0);
int  trace_ctl(int action, uint64 filter);
int  trace_read(uint64 ubuf, int max);
void trace_fork(struct proc *parent, struct proc *child);
#endif
