#include "ulib.h"
int main(void){
    int fp=u_getpid(), sp=getpid();
    printf("u_getpid=%d getpid=%d %s\n", fp, sp, fp==sp?"OK":"MISMATCH");
    unsigned long fu=u_uptime(), su=uptime();
    long d=(long)fu-(long)su; if(d<0)d=-d;
    printf("u_uptime=%d uptime=%d delta=%d %s\n",(int)fu,(int)su,(int)d,d<=2?"OK":"SKEW");
    struct usysinfo s; unsigned long last=0; int torn=0, myppid=-1;
    for(int i=0;i<20000;i++){
        if(u_snapshot(&s)<0){printf("snapshot failed\n");exit(1);}
        if(myppid<0)myppid=s.ppid;
        if(s.ppid!=myppid)torn++;
        if(s.ticks<last)torn++;
        last=s.ticks;
        if((i%4000)==0)getpid();
    }
    printf("consistency: 20000 snapshots, torn=%d %s\n", torn, torn==0?"OK":"TORN");
    struct usysinfo a,b; u_snapshot(&a);
    for(int i=0;i<5;i++)getpid();
    u_snapshot(&b);
    printf("syscall_count %d -> %d %s\n",(int)a.syscall_count,(int)b.syscall_count, b.syscall_count>a.syscall_count?"OK":"STUCK");
    exit(0);
}
