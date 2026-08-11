/* Lab 3: versioned shared kernel/user info page. */
#ifndef LUIT_USYSINFO_H
#define LUIT_USYSINFO_H
#define USYSINFO_VERSION 1
#define USYSINFO_VA      0x7FFFF000UL
struct usysinfo {
    uint32 version; volatile uint32 seq;
    int pid, ppid, hart;
    uint64 ticks, syscall_count, ctxsw_count;
    uint32 state_gen, _pad;
};
#endif
