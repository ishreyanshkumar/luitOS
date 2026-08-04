/* Lab 1 starter: pstree
 * Build a deterministic process tree from exactly one procstat() snapshot. */
#include "ulib.h"
#include "../kernel/param.h"

#define MAX_PROCESSES NPROC

static struct pstat processes[MAX_PROCESSES];
static int process_count;

const char *
state_name(int state)
{
    switch (state) {
    case 1: return "used";
    case 2: return "sleep";
    case 3: return "runble";
    case 4: return "run";
    case 5: return "zombie";
    default: return "?";
    }
}

static int
find_process_index(int pid)
{
    /* TODO-BEGIN T1: return the matching record index, or -1. */
    (void)pid;
    return -1;
    /* TODO-END T1 */
}

static void
sort_processes_by_pid(void)
{
    /* TODO-BEGIN T2: sort processes[0..process_count) by increasing pid. */
    /* A simple O(n^2) algorithm is sufficient because NPROC is 64. */
    /* TODO-END T2 */
}

static int
parse_positive_pid(const char *text, int *pid)
{
    /* TODO-BEGIN T3: validate a complete positive decimal integer safely. */
    (void)text;
    (void)pid;
    return -1;
    /* TODO-END T3 */
}

static void
print_subtree(int root_pid, int depth, char visited[])
{
    /* TODO-BEGIN T4:
     * 1. Locate root_pid in the snapshot.
     * 2. Detect and warn about a repeated visit/cycle.
     * 3. Mark the record before descending.
     * 4. Print two spaces per depth, then name(pid) [state].
     * 5. Recursively print every child whose ppid == root_pid.
     */
    (void)root_pid;
    (void)depth;
    (void)visited;
    /* TODO-END T4 */
}

static int
count_missing_parent_links(void)
{
    /* TODO-BEGIN T5:
     * Count records with ppid > 0 whose parent PID is absent from this
     * snapshot. Do not count the selected root merely because its parent is
     * outside the selected subtree.
     */
    return 0;
    /* TODO-END T5 */
}

int
main(int argc, char *argv[])
{
    int root_pid = 1;
    int missing_links;
    static char visited[MAX_PROCESSES];

    (void)find_process_index;     /* starter remains warning-free */
    (void)parse_positive_pid;

    if (argc > 2) {
        fprintf(2, "pstree: usage: pstree [root-pid]\n");
        exit(1);
    }

    /* TODO-BEGIN T6: parse the optional root PID. */
    if (argc == 2) {
        (void)argv;
        fprintf(2, "pstree: TODO T6 is not implemented\n");
        exit(1);
    }
    /* TODO-END T6 */

    /* The snapshot call is deliberately supplied: do not add another call. */
    process_count = procstat(processes, MAX_PROCESSES);

    /* TODO-BEGIN T7: validate process_count and the requested root. */
    (void)root_pid;
    fprintf(2, "pstree: TODO T7 is not implemented\n");
    exit(1);
    /* TODO-END T7 */

    sort_processes_by_pid();
    print_subtree(root_pid, 0, visited);

    missing_links = count_missing_parent_links();
    if (missing_links > 0)
        fprintf(2, "pstree: snapshot changed; %d parent link(s) missing\n",
                missing_links);

    exit(0);
}
