#include "ulib.h"
int main(void)
{
    int fp = freepages();
    printf("free pages: %d (%d KiB)\n", fp, fp * 4);
    exit(0);
}
