/* fdinfo <pid> - list open descriptors of a process. */
#include "ulib.h"
int main(int argc, char *argv[]){
    if(argc<2){ printf("usage: fdinfo pid\n"); exit(1); }
    int pid = atoi(argv[1]);
    const char *ty[] = {"none","pipe","file","dev"};
    printf("fd  type  inum  off\n");
    for(int fd=0; fd<16; fd++){
        struct fdinfo fi;
        if(fdstat(pid, fd, &fi)==0)
            printf("%d   %s  %d    %d\n", fd, (fi.type>=0&&fi.type<4)?ty[fi.type]:"?", fi.inum, fi.off);
    }
    exit(0);
}
