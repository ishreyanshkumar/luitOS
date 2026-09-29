/* grep with the classic tiny regexp: ^ $ . * (K&R exercise heritage). */
#include "ulib.h"

char buf[1024];
static int matchhere(char *, char *);
static int matchstar(int, char *, char *);

static int match(char *re, char *text)
{
    if (re[0] == '^') return matchhere(re + 1, text);
    do {
        if (matchhere(re, text)) return 1;
    } while (*text++ != '\0');
    return 0;
}
static int matchhere(char *re, char *text)
{
    if (re[0] == '\0') return 1;
    if (re[1] == '*')  return matchstar(re[0], re + 2, text);
    if (re[0] == '$' && re[1] == '\0') return *text == '\0';
    if (*text != '\0' && (re[0] == '.' || re[0] == *text))
        return matchhere(re + 1, text + 1);
    return 0;
}
static int matchstar(int c, char *re, char *text)
{
    do {
        if (matchhere(re, text)) return 1;
    } while (*text != '\0' && (*text++ == c || c == '.'));
    return 0;
}

static void grep(char *pattern, int fd)
{
    int n, m = 0;
    char *p, *q;
    while ((n = read(fd, buf + m, sizeof(buf) - m - 1)) > 0) {
        m += n;
        buf[m] = '\0';
        p = buf;
        while ((q = strchr(p, '\n')) != 0) {
            *q = 0;
            if (match(pattern, p)) {
                *q = '\n';
                write(1, p, q + 1 - p);
            } else
                *q = '\n';
            p = q + 1;
        }
        if (m > 0) {
            m -= p - buf;
            memmove(buf, p, m);
        }
    }
}

int main(int argc, char *argv[])
{
    if (argc <= 1) { fprintf(2, "usage: grep pattern [file...]\n"); exit(1); }
    if (argc == 2) { grep(argv[1], 0); exit(0); }
    for (int i = 2; i < argc; i++) {
        int fd = open(argv[i], O_RDONLY);
        if (fd < 0) { fprintf(2, "grep: cannot open %s\n", argv[i]); exit(1); }
        grep(argv[1], fd);
        close(fd);
    }
    exit(0);
}
