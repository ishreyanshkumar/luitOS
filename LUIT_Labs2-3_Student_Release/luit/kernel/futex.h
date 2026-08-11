/* Lab 6: futex - kernel support for fast userspace synchronization. */
#ifndef LUIT_FUTEX_H
#define LUIT_FUTEX_H
#define FUTEX_WAIT 0
#define FUTEX_WAKE 1
void futex_init(void);
int  futex_wait(uint64 uaddr, uint64 expected);
int  futex_wake(uint64 uaddr, int n);
#endif
