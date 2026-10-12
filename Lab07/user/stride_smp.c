#include "ulib.h"

#define NWORK 12
struct report { int tag; uint64 delta; int last_hart; uint64 migrations; };
static volatile uint64 sink;

static void fail(const char *m){ fprintf(2,"STRIDE_SMP: FAIL: %s\n",m); exit(1); }
static int write_full(int fd,const void*buf,int n){ const char*p=(const char*)buf;int o=0;while(o<n){int r=write(fd,p+o,n-o);if(r<=0)return-1;o+=r;}return 0; }
static int read_full(int fd,void*buf,int n){ char*p=(char*)buf;int o=0;while(o<n){int r=read(fd,p+o,n-o);if(r<=0)return-1;o+=r;}return 0; }

static void worker(int tag,int gatefd,int outfd,uint64 start,uint64 end){
    int t=25+(tag%6)*25;
    if(settickets(t)<0) exit(20+tag);
    char c; if(read(gatefd,&c,1)!=1) exit(40+tag);
    while(u_uptime()<start) sink=sink*1103515245UL+(uint64)tag;
    struct schedinfo a,b; if(schedinfo(&a)<0) exit(60+tag);
    while(u_uptime()<end){ for(int i=0;i<3000;i++) sink=sink*1664525UL+(uint64)(tag+1); }
    if(schedinfo(&b)<0) exit(80+tag);
    struct report r={tag,b.dispatches-a.dispatches,b.last_hart,b.migrations-a.migrations};
    if(write_full(outfd,&r,sizeof(r))<0) exit(100+tag);
    exit(0);
}

int main(void){
    int gate[2],out[2]; if(pipe(gate)<0||pipe(out)<0) fail("pipe");
    uint64 start=u_uptime()+10,end=start+120;
    for(int i=0;i<NWORK;i++){
        int pid=fork(); if(pid<0) fail("fork");
        if(pid==0){ close(gate[1]); close(out[0]); worker(i,gate[0],out[1],start,end); }
    }
    close(gate[0]); close(out[1]); char c='x';
    for(int i=0;i<NWORK;i++) if(write(gate[1],&c,1)!=1) fail("gate");
    close(gate[1]);
    int seen[NWORK]; for(int i=0;i<NWORK;i++) seen[i]=0;
    uint64 low=0,high=0;
    for(int i=0;i<NWORK;i++){
        struct report r; if(read_full(out[0],&r,sizeof(r))<0)fail("report");
        if(r.tag<0||r.tag>=NWORK||seen[r.tag])
            fail("tag/duplicate");
        seen[r.tag]=1;
        if(r.delta==0) fail("worker made no progress");
        if(r.last_hart<0||r.last_hart>=4) fail("invalid last_hart under CPUS=4");
        if(r.migrations>r.delta+2) fail("impossible migration count");
        if((r.tag%6)==0) low+=r.delta;
        if((r.tag%6)==5) high+=r.delta;
    }
    close(out[0]); for(int i=0;i<NWORK;i++) if(wait(0)<0)fail("wait");
    printf("stride_smp aggregate: low25=%l high150=%l\n",low,high);
    if(high<=low) fail("ticket weighting disappeared under SMP contention");
    printf("STRIDE_SMP: PASS\n"); exit(0);
}
