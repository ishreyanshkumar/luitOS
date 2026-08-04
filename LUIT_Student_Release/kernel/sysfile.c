/* FILE-RELATED SYSTEM CALLS. Argument-fetch helpers live in syscall.c;
 * process-related calls in sysproc territory at the bottom of syscall.c.
 *
 * THE ONE RULE, restated: user pointers are HOSTILE until proven mapped.
 * Everything crosses through copyin/copyout/copyinstr - see docs/ABI.md.
 */
#include "types.h"
#include "defs.h"
#include "fcntl.h"

/* Fetch the n'th arg as a file descriptor; return the struct file too. */
static int argfd(int n, int *pfd, struct file **pf)
{
    int fd;
    argint(n, &fd);
    if (fd < 0 || fd >= NOFILE) return -1;
    struct file *f = myproc()->ofile[fd];
    if (f == 0) return -1;
    if (pfd) *pfd = fd;
    if (pf)  *pf  = f;
    return 0;
}

/* Install f in the first free slot of the fd table. */
static int fdalloc(struct file *f)
{
    struct proc *p = myproc();
    for (int fd = 0; fd < NOFILE; fd++) {
        if (p->ofile[fd] == 0) {
            p->ofile[fd] = f;
            return fd;
        }
    }
    return -1;
}

uint64 sys_dup(void)
{
    struct file *f;
    if (argfd(0, 0, &f) < 0) return -1;
    int fd = fdalloc(f);
    if (fd < 0) return -1;
    filedup(f);
    return fd;
}

uint64 sys_read(void)
{
    struct file *f;
    int n;
    uint64 p;
    argaddr(1, &p);
    argint(2, &n);
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    return fileread(f, p, n);
}

uint64 sys_write(void)
{
    struct file *f;
    int n;
    uint64 p;
    argaddr(1, &p);
    argint(2, &n);
    if (argfd(0, 0, &f) < 0 || n < 0) return -1;
    return filewrite(f, p, n);
}

uint64 sys_close(void)
{
    int fd;
    struct file *f;
    if (argfd(0, &fd, &f) < 0) return -1;
    myproc()->ofile[fd] = 0;
    fileclose(f);
    return 0;
}

uint64 sys_fstat(void)
{
    struct file *f;
    uint64 st;
    argaddr(1, &st);
    if (argfd(0, 0, &f) < 0) return -1;
    return filestat(f, st);
}

/* Create a new hard link newpath -> the inode behind oldpath. */
uint64 sys_link(void)
{
    char name[DIRSIZ], newp[MAXPATH], oldp[MAXPATH];
    if (argstr(0, oldp, MAXPATH) < 0 || argstr(1, newp, MAXPATH) < 0) return -1;

    struct inode *ip = namei(oldp);
    if (ip == 0) return -1;

    ilock(ip);
    if (ip->type == T_DIR) {          /* hard links to dirs make cycles */
        iunlockput(ip);
        return -1;
    }
    ip->nlink++;
    iupdate(ip);
    iunlock(ip);

    struct inode *dp = nameiparent(newp, name);
    if (dp == 0) goto bad;
    ilock(dp);
    if (dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0) {
        iunlockput(dp);
        goto bad;
    }
    iunlockput(dp);
    iput(ip);
    return 0;

bad:
    ilock(ip);
    ip->nlink--;
    iupdate(ip);
    iunlockput(ip);
    return -1;
}

/* Is directory dp empty apart from . and ..? Caller holds dp->lock. */
static int isdirempty(struct inode *dp)
{
    struct dirent de;
    for (uint32 off = 2 * sizeof(de); off < dp->size; off += sizeof(de)) {
        if (readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
            panic("isdirempty: short read");
        if (de.inum != 0) return 0;
    }
    return 1;
}

uint64 sys_unlink(void)
{
    char name[DIRSIZ], path[MAXPATH];
    if (argstr(0, path, MAXPATH) < 0) return -1;

    struct inode *dp = nameiparent(path, name);
    if (dp == 0) return -1;
    ilock(dp);

    /* Cannot unlink "." or "..". */
    if (namecmp(name, ".") == 0 || namecmp(name, "..") == 0) goto bad;

    uint32 off;
    struct inode *ip = dirlookup(dp, name, &off);
    if (ip == 0) goto bad;
    ilock(ip);                        /* lock order: parent, then child */

    if (ip->nlink < 1) panic("unlink: nlink < 1");
    if (ip->type == T_DIR && !isdirempty(ip)) {
        iunlockput(ip);
        goto bad;
    }

    struct dirent de;
    memset(&de, 0, sizeof(de));
    if (writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
        panic("unlink: writei");
    if (ip->type == T_DIR) {
        dp->nlink--;                  /* the child's ".." no longer counts */
        iupdate(dp);
    }
    iunlockput(dp);

    ip->nlink--;
    iupdate(ip);
    iunlockput(ip);                   /* data freed in iput if last ref+link */
    return 0;

bad:
    iunlockput(dp);
    return -1;
}

/* Create path as type. Returns LOCKED inode, or 0. Handles the T_DIR case
 * (".", "..", parent nlink) and open(O_CREATE) racing an existing file. */
static struct inode *create(char *path, uint16 type, uint16 major, uint16 minor)
{
    char name[DIRSIZ];
    struct inode *dp = nameiparent(path, name);
    if (dp == 0) return 0;
    ilock(dp);

    struct inode *ip = dirlookup(dp, name, 0);
    if (ip != 0) {
        iunlockput(dp);
        ilock(ip);
        if (type == T_FILE && (ip->type == T_FILE || ip->type == T_DEV))
            return ip;                /* open(O_CREATE) of an existing file: fine */
        iunlockput(ip);
        return 0;
    }

    if ((ip = ialloc(dp->dev, type)) == 0) { iunlockput(dp); return 0; }

    ilock(ip);
    ip->major = major;
    ip->minor = minor;
    ip->nlink = 1;
    iupdate(ip);

    if (type == T_DIR) {
        /* "." and ".." - note ".." links the PARENT, whose nlink grows. */
        if (dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
            goto fail;
    }
    if (dirlink(dp, name, ip->inum) < 0) goto fail;
    if (type == T_DIR) {
        dp->nlink++;
        iupdate(dp);
    }
    iunlockput(dp);
    return ip;

fail:
    /* Something failed; undo the allocation. */
    ip->nlink = 0;
    iupdate(ip);
    iunlockput(ip);
    iunlockput(dp);
    return 0;
}

uint64 sys_open(void)
{
    char path[MAXPATH];
    int omode;
    argint(1, &omode);
    if (argstr(0, path, MAXPATH) < 0) return -1;

    struct inode *ip;
    if (omode & O_CREATE) {
        ip = create(path, T_FILE, 0, 0);
        if (ip == 0) return -1;
    } else {
        if ((ip = namei(path)) == 0) return -1;
        ilock(ip);
        if (ip->type == T_DIR && omode != O_RDONLY) {
            iunlockput(ip);
            return -1;
        }
    }
    if (ip->type == T_DEV && (ip->major < 0 || ip->major >= NDEV)) {
        iunlockput(ip);
        return -1;
    }

    struct file *f = filealloc();
    int fd;
    if (f == 0 || (fd = fdalloc(f)) < 0) {
        if (f) fileclose(f);
        iunlockput(ip);
        return -1;
    }

    if (ip->type == T_DEV) {
        f->type  = FD_DEVICE;
        f->major = ip->major;
    } else {
        f->type = FD_INODE;
        f->off  = 0;
    }
    f->ip       = ip;
    f->readable = !(omode & O_WRONLY);
    f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

    if ((omode & O_TRUNC) && ip->type == T_FILE)
        itrunc(ip);

    iunlock(ip);
    return fd;
}

uint64 sys_mkdir(void)
{
    char path[MAXPATH];
    if (argstr(0, path, MAXPATH) < 0) return -1;
    struct inode *ip = create(path, T_DIR, 0, 0);
    if (ip == 0) return -1;
    iunlockput(ip);
    return 0;
}

uint64 sys_chdir(void)
{
    char path[MAXPATH];
    struct proc *p = myproc();
    if (argstr(0, path, MAXPATH) < 0) return -1;
    struct inode *ip = namei(path);
    if (ip == 0) return -1;
    ilock(ip);
    if (ip->type != T_DIR) { iunlockput(ip); return -1; }
    iunlock(ip);
    iput(p->cwd);
    p->cwd = ip;
    return 0;
}

uint64 sys_pipe(void)
{
    uint64 fdarray;                   /* user pointer to int[2] */
    argaddr(0, &fdarray);

    struct file *rf, *wf;
    if (pipealloc(&rf, &wf) < 0) return -1;

    struct proc *p = myproc();
    int fd0 = -1, fd1 = -1;
    if ((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0) {
        if (fd0 >= 0) p->ofile[fd0] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    if (copyout(p->pagetable, fdarray, (char *)&fd0, sizeof(fd0)) < 0 ||
        copyout(p->pagetable, fdarray + sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0) {
        p->ofile[fd0] = 0;
        p->ofile[fd1] = 0;
        fileclose(rf);
        fileclose(wf);
        return -1;
    }
    return 0;
}

uint64 sys_exec(void)
{
    char path[MAXPATH];
    uint64 uargv, uarg;
    char *argv[MAXARG];

    if (argstr(0, path, MAXPATH) < 0) return -1;
    argaddr(1, &uargv);
    memset(argv, 0, sizeof(argv));

    int ret = -1;
    for (int i = 0; ; i++) {
        if (i >= MAXARG) goto out;
        if (copyin(myproc()->pagetable, (char *)&uarg,
                   uargv + sizeof(uint64) * i, sizeof(uint64)) < 0) goto out;
        if (uarg == 0) { argv[i] = 0; break; }
        argv[i] = palloc();
        if (!argv[i]) goto out;
        if (fetchstr(uarg, argv[i], PGSIZE) < 0) goto out;
    }
    ret = exec(path, argv);
out:
    /* Free EVERY page we allocated, on every path - the original version of
     * this function leaked argv pages on a bad pointer. Found in the audit. */
    for (int i = 0; i < MAXARG && argv[i]; i++) pfree(argv[i]);
    return ret;
}
