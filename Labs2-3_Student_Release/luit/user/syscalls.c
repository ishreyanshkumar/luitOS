/* syscalls - print the live syscall table from generated ABI metadata. */
#include "ulib.h"
#define MAX 64
int main(void){
    struct abinfo tab[MAX];
    int n = abimeta(tab, MAX);
    if(n<0){ printf("syscalls: abimeta failed\n"); exit(1); }
    printf("%d syscalls:\n", n);
    for(int i=0;i<n;i++) printf("  %d\t%s\n", tab[i].num, tab[i].name);
    exit(0);
}
