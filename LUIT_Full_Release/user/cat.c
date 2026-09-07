#include "ulib.h"
char buf[512];
static void cat(int fd)
{
    int n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        if (write(1, buf, n) != n) { fprintf(2, "cat: write error\n"); exit(1); }
    }
    if (n < 0) { fprintf(2, "cat: read error\n"); exit(1); }
}
int main(int argc, char *argv[])
{
    if (argc <= 1) { cat(0); exit(0); }
    for (int i = 1; i < argc; i++) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) { fprintf(2, "cat: cannot open %s\n", argv[i]); exit(1); }
        cat(fd);
        close(fd);
    }
    exit(0);
}
