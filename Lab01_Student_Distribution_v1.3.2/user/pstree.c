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
    for (int i = 0; i < process_count; i++) {
        if (processes[i].pid == pid) {
            return i;
        }
    }
    return -1;
    /* TODO-END T1 */

}

static void
sort_processes_by_pid(void)
{
    /* TODO-BEGIN T2: sort processes[0..process_count) by increasing pid. */
    for (int i = 0; i < process_count - 1; i++) {
        for (int j = 0; j < process_count - i - 1; j++) {
            if (processes[j].pid > processes[j + 1].pid) {
                struct pstat temp = processes[j];
                processes[j] = processes[j + 1];
                processes[j + 1] = temp;
            }
        }
    }
    /* TODO-END T2 */

}

static int
parse_positive_pid(const char *text, int *pid)
{
    /* TODO-BEGIN T3: validate a complete positive decimal integer safely. */
    if (text[0] == '\0') return -1;
    long long result = 0;
    for (int i = 0; text[i] != '\0'; i++) {
        if (text[i] < '0' || text[i] > '9') return -1;
        result = (result * 10) + (text[i] - '0');
        if (result > 2147483647LL) return -1; // Prevent overflow
    }
    if (result <= 0) return -1; // Must be strictly positive
    *pid = (int)result;
    return 0;
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
    int idx = find_process_index(root_pid);
    if (idx == -1) return;

    if (visited[idx]) {
        fprintf(2, "pstree: cycle detected\n");
        return;
    }
    visited[idx] = 1;

    for (int i = 0; i < depth * 2; i++) {
        fprintf(1, " ");
    }
    fprintf(1, "%s(%d) [%s]\n", processes[idx].name, processes[idx].pid, state_name(processes[idx].state));

    for (int i = 0; i < process_count; i++) {
        if (processes[i].ppid == root_pid) {
            print_subtree(processes[i].pid, depth + 1, visited);
        }
    }
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
    int missing = 0;
    for (int i = 0; i < process_count; i++) {
        if (processes[i].ppid > 0) {
            if (find_process_index(processes[i].ppid) == -1) {
                missing++;
            }
        }
    }
    return missing;
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
        if (parse_positive_pid(argv[1], &root_pid) == -1) {
            fprintf(2, "pstree: usage: pstree [root-pid]\n");
            exit(1);
        }
    }
    /* TODO-END T6 */

    /* The snapshot call is deliberately supplied: do not add another call. */
    process_count = procstat(processes, MAX_PROCESSES);

    /* TODO-BEGIN T7: validate process_count and the requested root. */
    if (process_count < 0) {
        fprintf(2, "pstree: procstat failed\n");
        exit(1);
    }
    if (find_process_index(root_pid) == -1) {
        fprintf(2, "pstree: pid %d not found\n", root_pid);
        exit(1);
    }
    /* TODO-END T7 */

    sort_processes_by_pid();
    print_subtree(root_pid, 0, visited);

    missing_links = count_missing_parent_links();
    if (missing_links > 0)
        fprintf(2, "pstree: snapshot changed; %d parent link(s) missing\n",
                missing_links);

    exit(0);
}
