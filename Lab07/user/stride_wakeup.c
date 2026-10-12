#include "ulib.h"

struct report { int tag; uint64 delta; };
static volatile uint64 sink;

static void fail(const char *m){ fprintf(2, "STRIDE_WAKEUP: FAIL: %s\n", m); exit(1); }
static int write_full(int fd, const void *buf, int n){ const char*p=(const char*)buf;int o=0;while(o<n){int r=write(fd,p+o,n-o);if(r<=0)return-1;o+=r;}return 0; }
static int read_full(int fd, void *buf, int n){ char*p=(char*)buf;int o=0;while(o<n){int r=read(fd,p+o,n-o);if(r<=0)return-1;o+=r;}return 0; }
static void burn(void){ for(int i=0;i<5000;i++) sink=sink*1664525UL+1013904223UL; }

static void runner_a(int gatefd, int wakefd, int outfd, uint64 start, uint64 measure, uint64 end){
    close(wakefd);
    char c; if(read(gatefd,&c,1)!=1) exit(11);
    while(u_uptime()<start) burn();
    while(u_uptime()<measure) burn();
    struct schedinfo a,b; if(schedinfo(&a)<0) exit(12);
    while(u_uptime()<end) burn();
    if(schedinfo(&b)<0) exit(13);
    struct report r={0,b.dispatches-a.dispatches};
    if(write_full(outfd,&r,sizeof(r))<0) exit(14);
    exit(0);
}

static void sleeper_b(int gatefd, int wakefd, int outfd, uint64 start, uint64 end){
    char c; if(read(gatefd,&c,1)!=1) exit(21);
    while(u_uptime()<start) burn();

    /* Block on a pipe, not sleep(n): this produces one long SLEEPING interval
     * rather than a wake/re-sleep on every global clock tick. */
    if(read(wakefd,&c,1)!=1) exit(22);

    struct schedinfo a,b; if(schedinfo(&a)<0) exit(23);
    while(u_uptime()<end) burn();
    if(schedinfo(&b)<0) exit(24);
    struct report r={1,b.dispatches-a.dispatches};
    if(write_full(outfd,&r,sizeof(r))<0) exit(25);
    exit(0);
}

int main(void){
    int gate[2],wakep[2],out[2];
    if(pipe(gate)<0||pipe(wakep)<0||pipe(out)<0) fail("pipe");
    uint64 start=u_uptime()+8, measure=start+55, end=measure+36;

    int a=fork(); if(a<0) fail("fork A");
    if(a==0){ close(gate[1]); close(wakep[1]); close(out[0]); runner_a(gate[0],wakep[0],out[1],start,measure,end); }
    int b=fork(); if(b<0) fail("fork B");
    if(b==0){ close(gate[1]); close(wakep[1]); close(out[0]); sleeper_b(gate[0],wakep[0],out[1],start,end); }

    close(gate[0]); close(wakep[0]); close(out[1]);
    char c='x';
    if(write(gate[1],&c,1)!=1||write(gate[1],&c,1)!=1) fail("gate");
    close(gate[1]);

    while(u_uptime()<start) ;
    uint64 now=u_uptime();
    int delay=(measure>now)?(int)(measure-now):0;
    if(delay>0 && sleep(delay)<0) fail("delay");
    if(write(wakep[1],&c,1)!=1) fail("wake pipe");
    close(wakep[1]);

    uint64 d[2]={0,0};
    for(int i=0;i<2;i++){ struct report r; if(read_full(out[0],&r,sizeof(r))<0)fail("report"); if(r.tag<0||r.tag>1)fail("tag"); d[r.tag]=r.delta; }
    close(out[0]); if(wait(0)<0||wait(0)<0) fail("wait");
    printf("stride_wakeup dispatches: runner=%l sleeper=%l\n",d[0],d[1]);
    uint64 total=d[0]+d[1];
    if(total<12) fail("measurement window too short");
    if(d[0]*4<total || d[1]*4<total) fail("stale-pass wakeup burst");
    printf("STRIDE_WAKEUP: PASS\n"); exit(0);
}
