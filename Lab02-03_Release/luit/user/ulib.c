#include <stdarg.h>
#include "ulib.h"

int strlen(const char *s){ int n=0; while(s[n]) n++; return n; }
int strcmp(const char *a, const char *b){
    while(*a && *a == *b){ a++; b++; }
    return (unsigned char)*a - (unsigned char)*b;
}
char *strcpy(char *d, const char *s){ char *o=d; while((*d++ = *s++)); return o; }
char *strchr(const char *s, char c){
    for(; *s; s++) if(*s == c) return (char*)s;
    return 0;
}
int atoi(const char *s){
    int n=0, neg=0;
    if(*s=='-'){ neg=1; s++; }
    while(*s>='0' && *s<='9') n = n*10 + (*s++ - '0');
    return neg ? -n : n;
}
void *memset(void *d, int c, int n){ char *p=d; while(n-->0) *p++=(char)c; return d; }
void *memmove(void *dst, const void *src, int n){
    char *d = dst; const char *s = src;
    if(s < d && s + n > d){ d += n; s += n; while(n-- > 0) *--d = *--s; }
    else while(n-- > 0) *d++ = *s++;
    return dst;
}

int stat(const char *path, struct stat *st){
    int fd = open(path, O_RDONLY);
    if(fd < 0) return -1;
    int r = fstat(fd, st);
    close(fd);
    return r;
}

static char digits[] = "0123456789abcdef";
static void putc_fd(int fd, char c){ write(fd, &c, 1); }
static void printint(int fd, long x, int base, int sign){
    char buf[24]; int i=0; unsigned long ux;
    if(sign && x<0){ ux=-x; } else { sign=0; ux=x; }
    do { buf[i++]=digits[ux%base]; } while((ux/=base)!=0);
    if(sign) buf[i++]='-';
    while(--i>=0) putc_fd(fd, buf[i]);
}
static void vprintf_fd(int fd, const char *fmt, va_list ap){
    for(int i=0; fmt[i]; i++){
        char c = fmt[i];
        if(c != '%'){ putc_fd(fd, c); continue; }
        c = fmt[++i];
        if(!c) break;
        if(c=='d') printint(fd, va_arg(ap,int),10,1);
        else if(c=='l') printint(fd, va_arg(ap,long),10,1);
        else if(c=='x') printint(fd, va_arg(ap,long),16,0);
        else if(c=='p'){ putc_fd(fd,'0'); putc_fd(fd,'x'); printint(fd, va_arg(ap,long),16,0); }
        else if(c=='c') putc_fd(fd, (char)va_arg(ap,int));
        else if(c=='s'){ const char*s=va_arg(ap,const char*); if(!s)s="(null)"; while(*s) putc_fd(fd, *s++); }
        else if(c=='%') putc_fd(fd, '%');
        else { putc_fd(fd,'%'); putc_fd(fd,c); }
    }
}
void printf(const char *fmt, ...){
    va_list ap; va_start(ap, fmt); vprintf_fd(1, fmt, ap); va_end(ap);
}
void fprintf(int fd, const char *fmt, ...){
    va_list ap; va_start(ap, fmt); vprintf_fd(fd, fmt, ap); va_end(ap);
}
char *gets(char *buf, int max){
    int i = 0;
    for(; i+1 < max; ){
        char c;
        int n = read(0, &c, 1);
        if(n < 1) break;
        buf[i++] = c;
        if(c == '\n') break;
    }
    buf[i] = '\0';
    return buf;
}

/* ---- Lab 3: shared-info-page fast accessors ---- */
static volatile struct usysinfo *usi(void){ return (volatile struct usysinfo *)USYSINFO_VA; }
int u_snapshot(struct usysinfo *out) {
    volatile struct usysinfo *u = usi();
    if (u->version != USYSINFO_VERSION) return -1;
    for (;;) {
        unsigned int s1 = u->seq;
        if (s1 & 1) continue;
        __sync_synchronize();
        out->pid=u->pid; out->ppid=u->ppid; out->hart=u->hart;
        out->ticks=u->ticks; out->syscall_count=u->syscall_count;
        out->ctxsw_count=u->ctxsw_count; out->state_gen=u->state_gen;
        __sync_synchronize();
        if (s1 == u->seq) return 0;
    }
}
int u_getpid(void){ struct usysinfo s; if(u_snapshot(&s)<0) return getpid(); return s.pid; }
unsigned long u_uptime(void){ struct usysinfo s; if(u_snapshot(&s)<0) return uptime(); return s.ticks; }

/* ---- Lab 6: threads & futex user library ---- */
#define FUTEX_WAIT 0
#define FUTEX_WAKE 1

int thread_create(void (*fn)(void*), void *arg, void *stack) {
    return clone((unsigned long)fn, (unsigned long)arg, (unsigned long)stack);
}

/* A simple futex-backed mutex. state: 0=free, 1=held. Uncontended lock/unlock
 * take no syscall (the __sync CAS succeeds); only contention traps. */
void mutex_lock(unsigned long *m) {
    while (__sync_val_compare_and_swap(m, 0, 1) != 0)
        futex((unsigned long)m, FUTEX_WAIT, 1, 0);   /* sleep while held */
}
void mutex_unlock(unsigned long *m) {
    __sync_lock_release(m);                           /* *m = 0 */
    futex((unsigned long)m, FUTEX_WAKE, 0, 1);        /* wake one waiter */
}
