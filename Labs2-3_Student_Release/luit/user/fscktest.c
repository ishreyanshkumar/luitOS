/* fscktest - Lab 9: run the FS consistency checker on a populated fs. */
#include "ulib.h"
int main(void){
    int fd = open("fk1", 0x200|0x002); write(fd, "aaaa", 4); close(fd);
    fd = open("fk2", 0x200|0x002);
    char big[2048]; for(int i=0;i<2048;i++) big[i]='x';
    for(int i=0;i<8;i++) write(fd, big, 2048);   /* spans direct + indirect blocks */
    close(fd);
    mkdir("fkd");
    fd = open("fkd/inner", 0x200|0x002); write(fd, "z", 1); close(fd);

    int r = fsck();
    printf("fsck on populated fs: %d %s\n", r, r==0 ? "CONSISTENT" : "VIOLATION");
    int r2 = fsck();
    printf("fsck repeatable: %s\n", r==r2 ? "OK" : "UNSTABLE");
    exit(0);
}
