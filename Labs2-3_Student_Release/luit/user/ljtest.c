/* ljtest - Lab 11: run a logged transaction and verify it committed + installed. */
#include "ulib.h"
int main(void){
    int r = logtest();
    printf("journal transaction: %s\n", r==0 ? "OK-COMMITTED" : "FAIL");
    exit(0);
}
