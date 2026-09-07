#include "ulib.h"
static const char *statename(int s)
{
    switch (s) {
    case 1: return "used";  case 2: return "sleep"; case 3: return "runble";
    case 4: return "run";   case 5: return "zombie";
    }
    return "?";
}
int main(void)
{
    static struct pstat tab[64];
    int n = procstat(tab, 64);
    if (n < 0) { fprintf(2, "ps: procstat failed\n"); exit(1); }
    printf("PID\tSTATE\tNAME\n");
    for (int i = 0; i < n; i++)
        printf("%d\t%s\t%s\n", tab[i].pid, statename(tab[i].state), tab[i].name);
    exit(0);
}
