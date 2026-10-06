#ifndef LUIT_MAILBOX_H
#define LUIT_MAILBOX_H

#define NMAILBOX 8
#define MBOX_CAP 8

void mailboxinit(void);
int  mbox_send(int id, int value);
int  mbox_recv(int id);
int  mbox_close(int id);

#endif
