#include "ulib.h"
int main(void){
    int N=64;
    char *buf=sbrk(N*4096);
    for(int i=0;i<N;i++) buf[i*4096]=(char)(i+1);
    int fb=freepages();
    int pid=fork();
    if(pid==0){
        for(int i=0;i<N;i++) if(buf[i*4096]!=(char)(i+1)){printf("child bad read\n");exit(1);}
        buf[0]=99; if(buf[0]!=99){printf("child write failed\n");exit(1);}
        int a=pgaudit(); printf("child: pgaudit=%d %s\n",a,a==0?"OK":"VIOLATION"); exit(0);
    }
    int fa=freepages(); int cost=fb-fa;
    printf("fork cost %d pages (eager ~%d) %s\n",cost,N,cost<N/2?"OK-LAZY":"NOT-LAZY");
    wait(0);
    printf("isolation: parent buf[0]=%d %s\n",buf[0],buf[0]==1?"OK":"BROKEN");
    int fd[2]; pipe(fd);
    int p2=fork();
    if(p2==0){ char *b=buf; write(fd[1],"hello",5); close(fd[1]);
        int n=read(fd[0],b,5);
        if(n==5&&b[0]=='h') printf("copyout-COW: OK\n"); else printf("copyout-COW: FAIL\n");
        int a=pgaudit(); printf("child2: pgaudit=%d %s\n",a,a==0?"OK":"VIOLATION"); exit(0);
    }
    wait(0);
    printf("copyout isolation: parent buf[0]=%d %s\n",buf[0],buf[0]==1?"OK":"BROKEN");
    exit(0);
}
