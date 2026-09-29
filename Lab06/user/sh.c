/* THE LUIT SHELL - fork, exec, wait, dup, pipe: the whole Unix process model
 * in one file. Supports: commands with arguments, < and > redirection,
 * pipelines, ; sequencing, & background jobs, and cd (a builtin - it must
 * be: chdir in a child would change the CHILD's cwd and then evaporate).
 *
 * Structure: a recursive-descent parser builds a small cmd tree
 * (EXEC/REDIR/PIPE/LIST/BACK), runcmd() walks it in a forked child.
 * Read parsecmd bottom-up: parseline -> parsepipe -> parseexec.
 */
#include "ulib.h"

#define MAXARGS 10

#define EXEC  1
#define REDIR 2
#define PIPE  3
#define LIST  4
#define BACK  5

struct cmd { int type; };
struct execcmd  { int type; char *argv[MAXARGS]; char *eargv[MAXARGS]; };
struct redircmd { int type; struct cmd *cmd; char *file; char *efile; int mode; int fd; };
struct pipecmd  { int type; struct cmd *left; struct cmd *right; };
struct listcmd  { int type; struct cmd *left; struct cmd *right; };
struct backcmd  { int type; struct cmd *cmd; };

int fork1(void);
void panic1(char *);
struct cmd *parsecmd(char *);
void runcmd(struct cmd *) __attribute__((noreturn));

void runcmd(struct cmd *cmd)
{
    int p[2];

    if (cmd == 0) exit(1);

    switch (cmd->type) {
    default:
        panic1("runcmd");

    case EXEC: {
        struct execcmd *ecmd = (struct execcmd *)cmd;
        if (ecmd->argv[0] == 0) exit(1);
        exec(ecmd->argv[0], ecmd->argv);
        fprintf(2, "sh: cannot run %s\n", ecmd->argv[0]);
        break;
    }
    case REDIR: {
        struct redircmd *rcmd = (struct redircmd *)cmd;
        /* close the target fd, open the file: it lands in that exact slot,
         * because open() always returns the LOWEST free descriptor. */
        close(rcmd->fd);
        if (open(rcmd->file, rcmd->mode) < 0) {
            fprintf(2, "sh: cannot open %s\n", rcmd->file);
            exit(1);
        }
        runcmd(rcmd->cmd);
        break;
    }
    case LIST: {
        struct listcmd *lcmd = (struct listcmd *)cmd;
        if (fork1() == 0) runcmd(lcmd->left);
        wait(0);
        runcmd(lcmd->right);
        break;
    }
    case PIPE: {
        struct pipecmd *pcmd = (struct pipecmd *)cmd;
        if (pipe(p) < 0) panic1("pipe");
        if (fork1() == 0) {              /* left side: stdout -> pipe */
            close(1);
            dup(p[1]);
            close(p[0]);
            close(p[1]);
            runcmd(pcmd->left);
        }
        if (fork1() == 0) {              /* right side: stdin <- pipe */
            close(0);
            dup(p[0]);
            close(p[0]);
            close(p[1]);
            runcmd(pcmd->right);
        }
        /* The parent MUST close both ends: a pipe reader only sees EOF when
         * every write fd is closed - including this one. Forget this and
         * `cat a | wc` hangs forever. (Lab 1's pingpong teaches the same.) */
        close(p[0]);
        close(p[1]);
        wait(0);
        wait(0);
        break;
    }
    case BACK: {
        struct backcmd *bcmd = (struct backcmd *)cmd;
        if (fork1() == 0) runcmd(bcmd->cmd);
        break;                           /* no wait: that IS "background" */
    }
    }
    exit(0);
}

int getcmd(char *buf, int nbuf)
{
    write(2, "luit$ ", 6);
    memset(buf, 0, nbuf);
    gets(buf, nbuf);
    if (buf[0] == 0) return -1;          /* EOF */
    return 0;
}

int main(void)
{
    static char buf[128];

    /* Ensure three file descriptors are open (defensive, like real sh). */
    int fd;
    while ((fd = open("/console", O_RDWR)) >= 0) {
        if (fd >= 3) { close(fd); break; }
    }

    while (getcmd(buf, sizeof(buf)) >= 0) {
        if (buf[0] == 'c' && buf[1] == 'd' && (buf[2] == ' ' || buf[2] == '\n')) {
            /* cd is a BUILTIN: it must change THIS process's cwd. */
            buf[strlen(buf) - 1] = 0;    /* chop \n */
            if (buf[2] == 0 || chdir(buf + 3) < 0)
                fprintf(2, "sh: cannot cd %s\n", buf + 3);
            continue;
        }
        if (fork1() == 0)
            runcmd(parsecmd(buf));
        wait(0);
    }
    exit(0);
}

void panic1(char *s)
{
    fprintf(2, "sh: %s\n", s);
    exit(1);
}

int fork1(void)
{
    int pid = fork();
    if (pid == -1) panic1("fork");
    return pid;
}

/* ---------------- constructors ---------------- */

static struct execcmd  xcmd_pool[8];
static struct redircmd rcmd_pool[8];
static struct pipecmd  pcmd_pool[4];
static struct listcmd  lcmd_pool[4];
static struct backcmd  bcmd_pool[4];
static int nx, nr, np, nl, nb;

struct cmd *execcmd1(void)
{
    struct execcmd *c = &xcmd_pool[nx++ % 8];
    memset(c, 0, sizeof(*c));
    c->type = EXEC;
    return (struct cmd *)c;
}
struct cmd *redircmd1(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
    struct redircmd *c = &rcmd_pool[nr++ % 8];
    memset(c, 0, sizeof(*c));
    c->type = REDIR; c->cmd = subcmd; c->file = file; c->efile = efile;
    c->mode = mode; c->fd = fd;
    return (struct cmd *)c;
}
struct cmd *pipecmd1(struct cmd *left, struct cmd *right)
{
    struct pipecmd *c = &pcmd_pool[np++ % 4];
    memset(c, 0, sizeof(*c));
    c->type = PIPE; c->left = left; c->right = right;
    return (struct cmd *)c;
}
struct cmd *listcmd1(struct cmd *left, struct cmd *right)
{
    struct listcmd *c = &lcmd_pool[nl++ % 4];
    memset(c, 0, sizeof(*c));
    c->type = LIST; c->left = left; c->right = right;
    return (struct cmd *)c;
}
struct cmd *backcmd1(struct cmd *subcmd)
{
    struct backcmd *c = &bcmd_pool[nb++ % 4];
    memset(c, 0, sizeof(*c));
    c->type = BACK; c->cmd = subcmd;
    return (struct cmd *)c;
}

/* ---------------- parsing ---------------- */

static char whitespace[] = " \t\r\n\v";
static char symbols[] = "<|>&;";

int gettoken(char **ps, char *es, char **q, char **eq)
{
    char *s = *ps;
    while (s < es && strchr(whitespace, *s)) s++;
    if (q) *q = s;
    int ret = *s;
    switch (*s) {
    case 0: break;
    case '|': case ';': case '&': case '<': case '>':
        s++;
        break;
    default:
        ret = 'a';
        while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s)) s++;
        break;
    }
    if (eq) *eq = s;
    while (s < es && strchr(whitespace, *s)) s++;
    *ps = s;
    return ret;
}

int peek(char **ps, char *es, char *toks)
{
    char *s = *ps;
    while (s < es && strchr(whitespace, *s)) s++;
    *ps = s;
    return *s && strchr(toks, *s);
}

struct cmd *parseline(char **, char *);
struct cmd *parsepipe(char **, char *);
struct cmd *parseexec(char **, char *);
struct cmd *nulterminate(struct cmd *);

struct cmd *parsecmd(char *s)
{
    nx = nr = np = nl = nb = 0;
    char *es = s + strlen(s);
    struct cmd *cmd = parseline(&s, es);
    peek(&s, es, "");
    if (s != es) {
        fprintf(2, "sh: leftovers: %s\n", s);
        panic1("syntax");
    }
    nulterminate(cmd);
    return cmd;
}

struct cmd *parseline(char **ps, char *es)
{
    struct cmd *cmd = parsepipe(ps, es);
    while (peek(ps, es, "&")) {
        gettoken(ps, es, 0, 0);
        cmd = backcmd1(cmd);
    }
    if (peek(ps, es, ";")) {
        gettoken(ps, es, 0, 0);
        cmd = listcmd1(cmd, parseline(ps, es));
    }
    return cmd;
}

struct cmd *parsepipe(char **ps, char *es)
{
    struct cmd *cmd = parseexec(ps, es);
    if (peek(ps, es, "|")) {
        gettoken(ps, es, 0, 0);
        cmd = pipecmd1(cmd, parsepipe(ps, es));
    }
    return cmd;
}

struct cmd *parseredirs(struct cmd *cmd, char **ps, char *es)
{
    while (peek(ps, es, "<>")) {
        int tok = gettoken(ps, es, 0, 0);
        char *q, *eq;
        if (gettoken(ps, es, &q, &eq) != 'a')
            panic1("missing file for redirection");
        switch (tok) {
        case '<':
            cmd = redircmd1(cmd, q, eq, O_RDONLY, 0);
            break;
        case '>':
            cmd = redircmd1(cmd, q, eq, O_WRONLY | O_CREATE | O_TRUNC, 1);
            break;
        }
    }
    return cmd;
}

struct cmd *parseexec(char **ps, char *es)
{
    struct execcmd *cmd = (struct execcmd *)execcmd1();
    struct cmd *ret = (struct cmd *)cmd;

    ret = parseredirs(ret, ps, es);
    int argc = 0;
    while (!peek(ps, es, "|)&;")) {
        char *q, *eq;
        int tok = gettoken(ps, es, &q, &eq);
        if (tok == 0) break;
        if (tok != 'a') panic1("syntax");
        cmd->argv[argc] = q;
        cmd->eargv[argc] = eq;
        argc++;
        if (argc >= MAXARGS) panic1("too many args");
        ret = parseredirs(ret, ps, es);
    }
    cmd->argv[argc] = 0;
    cmd->eargv[argc] = 0;
    return ret;
}

/* NUL-terminate all the counted strings the parser marked. */
struct cmd *nulterminate(struct cmd *cmd)
{
    if (cmd == 0) return 0;
    switch (cmd->type) {
    case EXEC: {
        struct execcmd *ecmd = (struct execcmd *)cmd;
        for (int i = 0; ecmd->argv[i]; i++)
            *ecmd->eargv[i] = 0;
        break;
    }
    case REDIR: {
        struct redircmd *rcmd = (struct redircmd *)cmd;
        nulterminate(rcmd->cmd);
        *rcmd->efile = 0;
        break;
    }
    case PIPE: {
        struct pipecmd *pcmd = (struct pipecmd *)cmd;
        nulterminate(pcmd->left);
        nulterminate(pcmd->right);
        break;
    }
    case LIST: {
        struct listcmd *lcmd = (struct listcmd *)cmd;
        nulterminate(lcmd->left);
        nulterminate(lcmd->right);
        break;
    }
    case BACK: {
        struct backcmd *bcmd = (struct backcmd *)cmd;
        nulterminate(bcmd->cmd);
        break;
    }
    }
    return cmd;
}
