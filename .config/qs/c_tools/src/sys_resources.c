#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>
#include <ctype.h>

static volatile int running = 1;

void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

typedef struct {
    char name[64];
    double cpu;
    double mem;
    double rss_mb;
    int count;
    double score;
} AppStat;

typedef struct {
    int pid;
    char name[64];
    unsigned long long utime;
    unsigned long long stime;
    unsigned long rss_pages;
} ProcSnapshot;

#define MAX_APPS 1024
#define MAX_PROCS 4096

static ProcSnapshot prev_procs[MAX_PROCS];
static int prev_proc_count = 0;
static unsigned long long prev_total_cpu = 0;
static unsigned long long prev_idle_cpu = 0;

static void get_cpu_times(unsigned long long *total, unsigned long long *idle) {
    FILE *f = fopen("/proc/stat", "r");
    if (!f) {
        *total = 0;
        *idle = 0;
        return;
    }
    char line[256];
    if (fgets(line, sizeof(line), f) && strncmp(line, "cpu ", 4) == 0) {
        unsigned long long u, n, s, idl, io, ir, so, st;
        if (sscanf(line + 4, "%llu %llu %llu %llu %llu %llu %llu %llu",
                   &u, &n, &s, &idl, &io, &ir, &so, &st) >= 4) {
            *total = u + n + s + idl + io + ir + so + st;
            *idle = idl + io;
        }
    }
    fclose(f);
}

static double get_cpu_freq_ghz(void) {
    FILE *f = fopen("/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq", "r");
    if (f) {
        unsigned long khz = 0;
        if (fscanf(f, "%lu", &khz) == 1) {
            fclose(f);
            return (double)khz / 1000000.0;
        }
        fclose(f);
    }
    return 2.4;
}

static int compare_apps(const void *a, const void *b) {
    const AppStat *aa = (const AppStat *)a;
    const AppStat *bb = (const AppStat *)b;
    if (bb->score > aa->score) return 1;
    if (bb->score < aa->score) return -1;
    return 0;
}

static void escape_json(const char *in, char *out, size_t out_sz) {
    size_t j = 0;
    for (size_t i = 0; in[i] && j + 2 < out_sz; i++) {
        if (in[i] == '"' || in[i] == '\\') {
            out[j++] = '\\';
            out[j++] = in[i];
        } else if (in[i] >= 32 && in[i] <= 126) {
            out[j++] = in[i];
        }
    }
    out[j] = '\0';
}

static void take_proc_snapshot(ProcSnapshot *snaps, int *count) {
    *count = 0;
    DIR *dir = opendir("/proc");
    if (!dir) return;

    struct dirent *ent;
    while ((ent = readdir(dir)) != NULL) {
        if (!isdigit(ent->d_name[0])) continue;
        int pid = atoi(ent->d_name);
        if (pid <= 0) continue;

        char path[64];
        snprintf(path, sizeof(path), "/proc/%d/stat", pid);
        FILE *fstat = fopen(path, "r");
        if (!fstat) continue;

        char comm[64] = {0};
        char state;
        int ppid, pgrp, session, tty_nr, tpgid;
        unsigned flags;
        unsigned long minflt, cminflt, majflt, cmajflt;
        unsigned long long utime = 0, stime = 0;
        long cutime, cstime, priority, nice, num_threads, itrealvalue;
        unsigned long long starttime;
        unsigned long vsize, rss = 0;

        int r = fscanf(fstat, "%d (%63[^)]) %c %d %d %d %d %d %u %lu %lu %lu %lu %llu %llu %ld %ld %ld %ld %ld %ld %llu %lu %lu",
                       &pid, comm, &state, &ppid, &pgrp, &session, &tty_nr, &tpgid,
                       &flags, &minflt, &cminflt, &majflt, &cmajflt, &utime, &stime,
                       &cutime, &cstime, &priority, &nice, &num_threads, &itrealvalue,
                       &starttime, &vsize, &rss);
        fclose(fstat);

        if (r >= 24 && vsize > 0 && *count < MAX_PROCS) {
            snaps[*count].pid = pid;
            snprintf(snaps[*count].name, sizeof(snaps[*count].name), "%s", comm);
            snaps[*count].utime = utime;
            snaps[*count].stime = stime;
            snaps[*count].rss_pages = rss;
            (*count)++;
        }
    }
    closedir(dir);
}

int main(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);
    signal(SIGHUP, handle_signal);

    long page_size_kb = sysconf(_SC_PAGESIZE) / 1024;
    int num_cores = (int)sysconf(_SC_NPROCESSORS_ONLN);
    if (num_cores <= 0) num_cores = 1;

    // Prime the baseline counters first
    get_cpu_times(&prev_total_cpu, &prev_idle_cpu);
    take_proc_snapshot(prev_procs, &prev_proc_count);

    // Initial 200ms pause to establish real delta before first frame
    usleep(200000);

    while (running) {
        if (getppid() == 1) break;

        unsigned long long curr_total_cpu = 0, curr_idle_cpu = 0;
        get_cpu_times(&curr_total_cpu, &curr_idle_cpu);

        unsigned long long total_delta = (curr_total_cpu > prev_total_cpu) ? (curr_total_cpu - prev_total_cpu) : 1;
        unsigned long long idle_delta = (curr_idle_cpu > prev_idle_cpu) ? (curr_idle_cpu - prev_idle_cpu) : 0;

        double total_cpu_pct = 0.0;
        if (total_delta > 0 && idle_delta <= total_delta) {
            total_cpu_pct = (1.0 - ((double)idle_delta / (double)total_delta)) * 100.0;
            if (total_cpu_pct < 0.0) total_cpu_pct = 0.0;
            if (total_cpu_pct > 100.0) total_cpu_pct = 100.0;
        }

        double mem_total_gb = 0, mem_used_gb = 0, mem_pct = 0;
        double swap_total_gb = 0, swap_used_gb = 0, swap_pct = 0;
        unsigned long long mem_total_kb = 0, mem_avail_kb = 0;
        unsigned long long swap_total_kb = 0, swap_free_kb = 0;

        FILE *fmem = fopen("/proc/meminfo", "r");
        if (fmem) {
            char mline[128];
            while (fgets(mline, sizeof(mline), fmem)) {
                if (strncmp(mline, "MemTotal:", 9) == 0) sscanf(mline + 9, "%llu", &mem_total_kb);
                else if (strncmp(mline, "MemAvailable:", 13) == 0) sscanf(mline + 13, "%llu", &mem_avail_kb);
                else if (strncmp(mline, "SwapTotal:", 10) == 0) sscanf(mline + 10, "%llu", &swap_total_kb);
                else if (strncmp(mline, "SwapFree:", 9) == 0) sscanf(mline + 9, "%llu", &swap_free_kb);
            }
            fclose(fmem);
        }

        if (mem_total_kb > 0) {
            mem_total_gb = (double)mem_total_kb / (1024.0 * 1024.0);
            mem_used_gb = (double)(mem_total_kb - mem_avail_kb) / (1024.0 * 1024.0);
            mem_pct = (double)(mem_total_kb - mem_avail_kb) / (double)mem_total_kb * 100.0;
        }
        if (swap_total_kb > 0) {
            swap_total_gb = (double)swap_total_kb / (1024.0 * 1024.0);
            swap_used_gb = (double)(swap_total_kb - swap_free_kb) / (1024.0 * 1024.0);
            swap_pct = (double)(swap_total_kb - swap_free_kb) / (double)swap_total_kb * 100.0;
        }

        ProcSnapshot curr_procs[MAX_PROCS];
        int curr_proc_count = 0;
        take_proc_snapshot(curr_procs, &curr_proc_count);

        AppStat apps[MAX_APPS];
        int app_count = 0;

        for (int i = 0; i < curr_proc_count; i++) {
            int pid = curr_procs[i].pid;
            const char *comm = curr_procs[i].name;
            unsigned long long curr_p_cpu = curr_procs[i].utime + curr_procs[i].stime;
            unsigned long rss = curr_procs[i].rss_pages;

            // Find matching process in previous snapshot
            int prev_found = 0;
            unsigned long long prev_p_cpu = 0;
            for (int p = 0; p < prev_proc_count; p++) {
                if (prev_procs[p].pid == pid) {
                    prev_p_cpu = prev_procs[p].utime + prev_procs[p].stime;
                    prev_found = 1;
                    break;
                }
            }

            double p_cpu_pct = 0.0;
            if (prev_found && curr_p_cpu >= prev_p_cpu && total_delta > 0) {
                p_cpu_pct = ((double)(curr_p_cpu - prev_p_cpu) / (double)total_delta) * 100.0 * (double)num_cores;
                if (p_cpu_pct > 100.0 * num_cores) p_cpu_pct = 100.0 * num_cores;
            }

            double p_mem_pct = (mem_total_kb > 0) ? (((double)(rss * page_size_kb) / (double)mem_total_kb) * 100.0) : 0.0;
            double p_rss_mb = (double)(rss * page_size_kb) / 1024.0;

            // Group by app name
            int found = -1;
            for (int a = 0; a < app_count; a++) {
                if (strcmp(apps[a].name, comm) == 0) {
                    found = a;
                    break;
                }
            }

            if (found >= 0) {
                apps[found].cpu += p_cpu_pct;
                apps[found].mem += p_mem_pct;
                apps[found].rss_mb += p_rss_mb;
                apps[found].count++;
            } else if (app_count < MAX_APPS) {
                snprintf(apps[app_count].name, sizeof(apps[app_count].name), "%s", comm);
                apps[app_count].cpu = p_cpu_pct;
                apps[app_count].mem = p_mem_pct;
                apps[app_count].rss_mb = p_rss_mb;
                apps[app_count].count = 1;
                app_count++;
            }
        }

        // Copy curr_procs to prev_procs
        memcpy(prev_procs, curr_procs, sizeof(ProcSnapshot) * curr_proc_count);
        prev_proc_count = curr_proc_count;
        prev_total_cpu = curr_total_cpu;
        prev_idle_cpu = curr_idle_cpu;

        for (int i = 0; i < app_count; i++) {
            apps[i].score = apps[i].cpu + apps[i].mem;
        }
        qsort(apps, app_count, sizeof(AppStat), compare_apps);

        printf("{\"cpu\": {\"usage\": %.1f, \"cores\": %d, \"freq\": %.2f}, "
               "\"memory\": {\"used_gb\": %.2f, \"total_gb\": %.2f, \"usage\": %.1f}, "
               "\"swap\": {\"used_gb\": %.2f, \"total_gb\": %.2f, \"usage\": %.1f}, "
               "\"top_apps\": [",
               total_cpu_pct, num_cores, get_cpu_freq_ghz(),
               mem_used_gb, mem_total_gb, mem_pct,
               swap_used_gb, swap_total_gb, swap_pct);

        int max_out = app_count < 10 ? app_count : 10;
        for (int i = 0; i < max_out; i++) {
            char clean_name[64];
            escape_json(apps[i].name, clean_name, sizeof(clean_name));
            printf("%s{\"name\": \"%s\", \"cpu\": %.1f, \"mem\": %.1f, \"rss_mb\": %.1f, \"count\": %d, \"score\": %.1f}",
                   (i > 0 ? ", " : ""),
                   clean_name, apps[i].cpu, apps[i].mem, apps[i].rss_mb, apps[i].count, apps[i].score);
        }
        printf("]}\n");
        fflush(stdout);

        static int first_sample = 1;
        if (first_sample) {
            first_sample = 0;
            struct timespec req = {0, 650000000};
            nanosleep(&req, NULL);
        } else {
            struct timespec req = {1, 500000000};
            nanosleep(&req, NULL);
        }
    }

    return 0;
}
