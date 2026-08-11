/* ljcrash - Lab 11: inject a crash after commit; reboot must recover. */
#include "ulib.h"
int main(int argc, char **argv){
    if(argc>1 && argv[1][0]=='v'){
        int r = logverify();
        printf("recovery after crash: %s\n", r==0 ? "OK-REPLAYED" : "FAIL-LOST");
    } else {
        logcrash();
        printf("crash injected (committed, not installed) - reboot to recover\n");
    }
    exit(0);
}
