#include "ulib.h"
#include "../kernel/types.h"
#include "../kernel/fs.h"

static char *fmtname(char *path)
{
    static char buf[DIRSIZ + 1];
    char *p;
    for (p = path + strlen(path); p >= path && *p != '/'; p--)
        ;
    p++;
    if (strlen(p) >= DIRSIZ) return p;
    memmove(buf, p, strlen(p));
    memset(buf + strlen(p), ' ', DIRSIZ - strlen(p));
    buf[DIRSIZ] = 0;
    return buf;
}

static void ls(char *path)
{
    int fd = open(path, O_RDONLY);
    if (fd < 0) { fprintf(2, "ls: cannot open %s\n", path); return; }
    struct stat st;
    if (fstat(fd, &st) < 0) { fprintf(2, "ls: cannot stat %s\n", path); close(fd); return; }

    char buf[512], *p;
    struct dirent de;
    switch (st.type) {
    case T_DEV:
    case T_FILE:
        printf("%s %d %d %l\n", fmtname(path), st.type, st.ino, st.size);
        break;
    case T_DIR:
        if (strlen(path) + 1 + DIRSIZ + 1 > sizeof(buf)) {
            printf("ls: path too long\n");
            break;
        }
        strcpy(buf, path);
        p = buf + strlen(buf);
        *p++ = '/';
        while (read(fd, &de, sizeof(de)) == sizeof(de)) {
            if (de.inum == 0) continue;
            memmove(p, de.name, DIRSIZ);
            p[DIRSIZ] = 0;
            if (stat(buf, &st) < 0) { printf("ls: cannot stat %s\n", buf); continue; }
            printf("%s %d %d %l\n", fmtname(buf), st.type, st.ino, st.size);
        }
        break;
    }
    close(fd);
}

int main(int argc, char *argv[])
{
    if (argc < 2) { ls("."); exit(0); }
    for (int i = 1; i < argc; i++) ls(argv[i]);
    exit(0);
}
