#ifndef LUIT_SCHEDINFO_H
#define LUIT_SCHEDINFO_H

/* Lab 7 stride-scheduler constants and read-only user-visible snapshot. */
#define STRIDE_DEFAULT_TICKETS 100
#define STRIDE_MIN_TICKETS       1
#define STRIDE_MAX_TICKETS    1000
#define STRIDE_BIG        10000000UL

struct schedinfo {
    int pid;
    int tickets;
    uint64 stride;
    uint64 pass;
    uint64 dispatches;
    int last_hart;
    uint64 migrations;
};

#endif
