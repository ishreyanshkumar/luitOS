/* Implementation note. */




#include "types.h"
#include "hal.h"
#include "riscv.h"
#include "defs.h"

void    hal_timer_init(void)          { hal_timer_next(1000000); }
uint64  hal_time_read(void)           { return r_time(); }
void    hal_timer_set(uint64 dl)      { sbi_set_timer(dl); }
void    hal_timer_ack(void)           { /* SBI: next set_timer clears STIP */ }
void    hal_timer_next(uint64 iv)     { hal_timer_set(hal_time_read() + iv); }
