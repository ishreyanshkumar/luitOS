/* pstree - print the process tree from init (pid 1) using procstat's ppid. */
#include "ulib.h"
#define MAXP 64
static struct pstat ps[MAXP];
static int n;
static const char *st(int s){ const char*t[]={"unused","used","sleep","runble","run","zombie"}; return (s>=0&&s<6)?t[s]:"?"; }
static void rec(int pid, int depth){
    for(int i=0;i<n;i++){
        if(ps[i].ppid==pid && ps[i].pid!=pid){
            for(int d=0;d<depth;d++) printf("  ");
            printf("%s(%d) [%s]\n", ps[i].name, ps[i].pid, st(ps[i].state));
            rec(ps[i].pid, depth+1);
        }
    }
}
int main(void){
    n = procstat(ps, MAXP);
    if(n<0){ printf("pstree: procstat failed\n"); exit(1); }
    /* print root(s): pid 1 (init) and anything whose parent isn't present */
    for(int i=0;i<n;i++) if(ps[i].pid==1){ printf("%s(%d) [%s]\n", ps[i].name, ps[i].pid, st(ps[i].state)); rec(1,1); }
    exit(0);
}
