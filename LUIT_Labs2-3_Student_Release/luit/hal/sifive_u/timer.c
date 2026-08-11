/* Timer HAL, qemu_virt backend. We go through SBI rather than banging the
 * CLINT directly: the CLINT is an M-mode device and OpenSBI owns it. S-mode
 * code that writes mtimecmp "works" on some cores and traps on others - the
 * SBI TIME extension is the architecturally portable interface, and it is
 * also why this same backend is the starting point for SHAKTI in Lab 12. */
#include "types.h"
#include "hal.h"
#include "riscv.h"
#include "defs.h"

void    hal_timer_init(void)          { hal_timer_next(1000000); }
uint64  hal_time_read(void)           { return r_time(); }
void    hal_timer_set(uint64 dl)      { sbi_set_timer(dl); }
void    hal_timer_ack(void)           { /* SBI: next set_timer clears STIP */ }
void    hal_timer_next(uint64 iv)     { hal_timer_set(hal_time_read() + iv); }
