#include "types.h"
#include "defs.h"
void *memset(void *dst, int c, usize n){ char *d=dst; while(n--) *d++=(char)c; return dst; }
void *memmove(void *dst, const void *src, usize n){
    char *d=dst; const char *s=src;
    if (d < s) { while(n--) *d++ = *s++; }
    else { d+=n; s+=n; while(n--) *--d = *--s; }
    return dst;
}
int memcmp(const void *a, const void *b, usize n){
    const uint8 *x=a,*y=b;
    while(n--){ if(*x != *y) return *x - *y; x++; y++; }
    return 0;
}
int strncmp(const char *a, const char *b, usize n){
    while(n > 0 && *a && *a == *b){ a++; b++; n--; }
    if(n == 0) return 0;
    return (uint8)*a - (uint8)*b;
}
char *strncpy(char *d, const char *s, int n){
    char *r=d;
    while(n-- > 0 && (*d++ = *s++) != 0) ;
    while(n-- > 0) *d++ = 0;
    return r;
}
int strlen(const char *s){ int n=0; while(s[n]) n++; return n; }
