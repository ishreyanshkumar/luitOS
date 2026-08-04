#include "ulib.h"
int main(int argc, char *argv[])
{
    if (argc < 2) { fprintf(2, "usage: mkdir dir...\n"); exit(1); }
    for (int i = 1; i < argc; i++)
        if (mkdir(argv[i]) < 0) { fprintf(2, "mkdir: %s failed\n", argv[i]); break; }
    exit(0);
}
