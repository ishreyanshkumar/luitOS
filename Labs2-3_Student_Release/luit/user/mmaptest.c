/* mmaptest - Lab 10: lazy file-backed mmap read; MAP_SHARED write-back. */
#include "ulib.h"
int main(void){
    /* create a file with known content */
    int fd = open("mm_f", 0x200|0x002);   /* O_CREATE|O_RDWR */
    if(fd<0){ printf("create failed\n"); exit(1); }
    char data[64]; for(int i=0;i<64;i++) data[i]='A'+(i%26);
    write(fd, data, 64);
    close(fd);

    /* 1) map read-only, lazily fault it in, verify contents */
    fd = open("mm_f", 0x002);             /* O_RDWR */
    char *m = mmap(0, 64, PROT_READ, MAP_SHARED, fd, 0);
    if(m == (char*)-1 || m == 0){ printf("mmap failed\n"); exit(1); }
    int ok = 1;
    for(int i=0;i<64;i++) if(m[i] != 'A'+(i%26)) ok = 0;   /* first access faults in */
    printf("lazy read: %s\n", ok ? "OK" : "FAIL");
    munmap(m, 64);

    /* 2) map read-write MAP_SHARED, modify, unmap (write-back), re-read file */
    char *w = mmap(0, 64, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    if(w == (char*)-1 || w == 0){ printf("mmap rw failed\n"); exit(1); }
    w[0] = 'Z'; w[1] = 'Y';
    munmap(w, 64);                        /* should flush to the file */
    close(fd);

    fd = open("mm_f", 0);
    char buf[64]; read(fd, buf, 64); close(fd);
    printf("write-back: %s\n", (buf[0]=='Z' && buf[1]=='Y') ? "OK" : "FAIL");
    exit(0);
}
