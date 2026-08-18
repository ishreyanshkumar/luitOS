/* renametest - Lab 9: rename moves a name; old vanishes, new has the data. */
#include "ulib.h"
int main(void){
    /* create a file with known content */
    int fd = open("rn_a", 0x200|0x002);  /* O_CREATE|O_RDWR */
    if(fd<0){ printf("create failed\n"); exit(1); }
    write(fd, "hello-rename", 12);
    close(fd);

    /* rename it */
    if(rename("rn_a", "rn_b") < 0){ printf("rename failed\n"); exit(1); }

    /* old name must be gone */
    fd = open("rn_a", 0);
    printf("old name gone: %s\n", fd<0 ? "OK" : "STILL-EXISTS");
    if(fd>=0) close(fd);

    /* new name must have the data */
    fd = open("rn_b", 0);
    if(fd<0){ printf("new name missing: FAIL\n"); exit(1); }
    char buf[16]; int n = read(fd, buf, 12); buf[n>0?n:0]=0;
    close(fd);
    printf("new name data: '%s' %s\n", buf, (n==12 && buf[0]=='h') ? "OK":"FAIL");

    /* rename onto an existing name should fail */
    int fd2 = open("rn_c", 0x200|0x002); write(fd2,"x",1); close(fd2);
    printf("rename onto existing: %s\n", rename("rn_b","rn_c")<0 ? "OK-REFUSED":"WRONGLY-ALLOWED");

    exit(0);
}
