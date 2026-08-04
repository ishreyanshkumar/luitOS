#include "ulib.h"
char buf[512];
static void wc(int fd, char *name)
{
    int l = 0, w = 0, c = 0, inword = 0, n;
    while ((n = read(fd, buf, sizeof(buf))) > 0) {
        for (int i = 0; i < n; i++) {
            c++;
            if (buf[i] == '\n') l++;
            if (buf[i] == ' ' || buf[i] == '\t' || buf[i] == '\n' || buf[i] == '\r')
                inword = 0;
            else if (!inword) { w++; inword = 1; }
        }
    }
    if (n < 0) { fprintf(2, "wc: read error\n"); exit(1); }
    printf("%d %d %d %s\n", l, w, c, name);
}
int main(int argc, char *argv[])
{
    if (argc <= 1) { wc(0, ""); exit(0); }
    for (int i = 1; i < argc; i++) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) { fprintf(2, "wc: cannot open %s\n", argv[i]); exit(1); }
        wc(fd, argv[i]);
        close(fd);
    }
    exit(0);
}
