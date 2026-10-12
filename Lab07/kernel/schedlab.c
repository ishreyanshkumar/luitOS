/* Lab 7 supplied syscall boundary and scheduler-stat snapshot. */
#include "types.h"
#include "defs.h"
#include "schedinfo.h"

uint64
sys_settickets(void)
{
    int tickets;
    argint(0, &tickets);
    return (uint64)set_tickets(tickets);
}

uint64
sys_schedinfo(void)
{
    uint64 uaddr;
    argaddr(0, &uaddr);
    if (uaddr == 0)
        return (uint64)-1;
    return (uint64)get_schedinfo(uaddr);
}
