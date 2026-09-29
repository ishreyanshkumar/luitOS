/* Lab 3: versioned shared kernel/user information page.
 * This header is part of the ABI between the Luit kernel and user programs.
 * The layout and fixed virtual address are supplied by the release. */
#ifndef LUIT_USYSINFO_H
#define LUIT_USYSINFO_H

#define USYSINFO_VERSION 1
#define USYSINFO_VA      0x7FFFF000UL

struct usysinfo {
    uint32 version;
    volatile uint32 seq;
    int pid;
    int hart;
    uint64 ticks;
    uint64 syscall_count;
    uint64 ctxsw_count;
    uint32 state_gen;
};

#endif
