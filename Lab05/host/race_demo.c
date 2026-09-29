#define _POSIX_C_SOURCE 200809L
#include <errno.h>
#include <pthread.h>
#include <sched.h>
#include <stdatomic.h>
#include <stdint.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static _Atomic unsigned long long counter;
static pthread_mutex_t counter_lock = PTHREAD_MUTEX_INITIALIZER;

enum mode_kind { MODE_UNSAFE, MODE_MUTEX };

struct worker_arg {
    unsigned long iterations;
    enum mode_kind mode;
};

static void *worker(void *vp)
{
    struct worker_arg *arg = (struct worker_arg *)vp;

    for (unsigned long i = 0; i < arg->iterations; i++) {
        if (arg->mode == MODE_MUTEX) {
            int rc = pthread_mutex_lock(&counter_lock);
            if (rc != 0) {
                fprintf(stderr, "pthread_mutex_lock failed: %s\n", strerror(rc));
                abort();
            }

            unsigned long long old =
                atomic_load_explicit(&counter, memory_order_relaxed);
            atomic_store_explicit(&counter, old + 1, memory_order_relaxed);

            rc = pthread_mutex_unlock(&counter_lock);
            if (rc != 0) {
                fprintf(stderr, "pthread_mutex_unlock failed: %s\n", strerror(rc));
                abort();
            }
        } else {
            /*
             * Each individual load/store is atomic, so the C program has no
             * data-race undefined behaviour.  The compound read-modify-write
             * is intentionally NOT atomic.  Two threads can therefore read
             * the same old value and overwrite one another's increment.
             */
            unsigned long long old =
                atomic_load_explicit(&counter, memory_order_relaxed);
            if ((i & 63UL) == 0)
                sched_yield();
            atomic_store_explicit(&counter, old + 1, memory_order_relaxed);
        }
    }
    return NULL;
}

static unsigned long parse_positive(const char *s, const char *what)
{
    char *end = NULL;
    errno = 0;
    unsigned long v = strtoul(s, &end, 10);
    if (errno != 0 || end == s || *end != '\0' || v == 0) {
        fprintf(stderr, "%s must be a positive decimal integer\n", what);
        exit(2);
    }
    return v;
}

int main(int argc, char **argv)
{
    if (argc != 4 ||
        (strcmp(argv[1], "unsafe") != 0 && strcmp(argv[1], "mutex") != 0)) {
        fprintf(stderr, "usage: %s unsafe|mutex THREADS INCREMENTS_PER_THREAD\n",
                argv[0]);
        return 2;
    }

    enum mode_kind mode = strcmp(argv[1], "mutex") == 0 ? MODE_MUTEX : MODE_UNSAFE;
    unsigned long nthreads = parse_positive(argv[2], "THREADS");
    unsigned long iterations = parse_positive(argv[3], "INCREMENTS_PER_THREAD");

    if (nthreads > 256) {
        fprintf(stderr, "THREADS must be <= 256\n");
        return 2;
    }

    if (iterations > ULLONG_MAX / nthreads) {
        fprintf(stderr, "expected count would overflow\n");
        return 2;
    }

    pthread_t *threads = calloc(nthreads, sizeof(*threads));
    struct worker_arg *args = calloc(nthreads, sizeof(*args));
    if (!threads || !args) {
        fprintf(stderr, "allocation failed\n");
        free(threads);
        free(args);
        return 2;
    }

    atomic_store_explicit(&counter, 0, memory_order_relaxed);

    for (unsigned long i = 0; i < nthreads; i++) {
        args[i].iterations = iterations;
        args[i].mode = mode;
        int rc = pthread_create(&threads[i], NULL, worker, &args[i]);
        if (rc != 0) {
            fprintf(stderr, "pthread_create failed at thread %lu: %s\n",
                    i, strerror(rc));
            return 2;
        }
    }

    for (unsigned long i = 0; i < nthreads; i++) {
        int rc = pthread_join(threads[i], NULL);
        if (rc != 0) {
            fprintf(stderr, "pthread_join failed: %s\n", strerror(rc));
            return 2;
        }
    }

    unsigned long long expected =
        (unsigned long long)nthreads * (unsigned long long)iterations;
    unsigned long long actual =
        atomic_load_explicit(&counter, memory_order_relaxed);

    printf("mode=%s threads=%lu increments/thread=%lu\n",
           mode == MODE_MUTEX ? "mutex" : "unsafe", nthreads, iterations);
    printf("expected=%llu actual=%llu lost=%llu\n",
           expected, actual, expected >= actual ? expected - actual : 0ULL);

    free(args);
    free(threads);

    if (mode == MODE_MUTEX && actual != expected) {
        fprintf(stderr, "FAIL: mutex-protected count is incorrect\n");
        return 1;
    }

    if (mode == MODE_MUTEX)
        printf("PASS: mutex protected the compound update\n");
    else if (actual != expected)
        printf("OBSERVED: lost update(s)\n");
    else
        printf("OBSERVED: this run happened to finish without a lost update; repeat it\n");

    return 0;
}
