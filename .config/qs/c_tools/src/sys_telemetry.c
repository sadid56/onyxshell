#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <time.h>

static volatile int running = 1;

void handle_signal(int sig) {
    (void)sig;
    running = 0;
}

static void get_net_bytes(unsigned long long *rx, unsigned long long *tx) {
    *rx = 0;
    *tx = 0;
    FILE *f = fopen("/proc/net/dev", "r");
    if (!f) return;

    char line[256];
    // Skip 2 header lines
    if (!fgets(line, sizeof(line), f)) { fclose(f); return; }
    if (!fgets(line, sizeof(line), f)) { fclose(f); return; }

    while (fgets(line, sizeof(line), f)) {
        char *colon = strchr(line, ':');
        if (!colon) continue;

        // Check if interface is loopback
        char iface[32] = {0};
        char *p = line;
        while (*p == ' ') p++;
        int i = 0;
        while (p < colon && i < 31 && *p != ' ') {
            iface[i++] = *p++;
        }
        iface[i] = '\0';
        if (strcmp(iface, "lo") == 0) continue;

        unsigned long long r_bytes = 0, t_bytes = 0;
        unsigned long long dummy;
        // colon points to ":", data starts right after
        int count = sscanf(colon + 1, "%llu %llu %llu %llu %llu %llu %llu %llu %llu",
                           &r_bytes, &dummy, &dummy, &dummy, &dummy, &dummy, &dummy, &dummy,
                           &t_bytes);
        if (count >= 9) {
            *rx += r_bytes;
            *tx += t_bytes;
        }
    }
    fclose(f);
}

static void format_speed(double bytes_per_sec, char *out, size_t out_sz) {
    if (bytes_per_sec < 1024.0) {
        snprintf(out, out_sz, "%d B/s", (int)bytes_per_sec);
    } else if (bytes_per_sec < 1024.0 * 1024.0) {
        snprintf(out, out_sz, "%.1f KB/s", bytes_per_sec / 1024.0);
    } else {
        snprintf(out, out_sz, "%.1f MB/s", bytes_per_sec / (1024.0 * 1024.0));
    }
}

static void get_cpu_times(unsigned long long *total, unsigned long long *idle) {
    *total = 0;
    *idle = 0;
    FILE *f = fopen("/proc/stat", "r");
    if (!f) return;

    char line[256];
    if (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "cpu ", 4) == 0) {
            unsigned long long user, nice, system, idl, iowait, irq, softirq, steal;
            if (sscanf(line + 4, "%llu %llu %llu %llu %llu %llu %llu %llu",
                       &user, &nice, &system, &idl, &iowait, &irq, &softirq, &steal) >= 4) {
                *idle = idl + iowait;
                *total = user + nice + system + idl + iowait + irq + softirq + steal;
            }
        }
    }
    fclose(f);
}

static void get_memory_info(double *mem_usage, double *swap_usage) {
    *mem_usage = 0.0;
    *swap_usage = 0.0;
    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return;

    unsigned long long total = 0, available = 0;
    unsigned long long swap_total = 0, swap_free = 0;

    char line[128];
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "MemTotal:", 9) == 0) {
            sscanf(line + 9, "%llu", &total);
        } else if (strncmp(line, "MemAvailable:", 13) == 0) {
            sscanf(line + 13, "%llu", &available);
        } else if (strncmp(line, "SwapTotal:", 10) == 0) {
            sscanf(line + 10, "%llu", &swap_total);
        } else if (strncmp(line, "SwapFree:", 9) == 0) {
            sscanf(line + 9, "%llu", &swap_free);
        }
    }
    fclose(f);

    if (total > 0 && total >= available) {
        *mem_usage = ((double)(total - available) / (double)total) * 100.0;
    }
    if (swap_total > 0 && swap_total >= swap_free) {
        *swap_usage = ((double)(swap_total - swap_free) / (double)swap_total) * 100.0;
    }
}

static double get_time_sec(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + (double)ts.tv_nsec / 1e9;
}

int main(void) {
    signal(SIGTERM, handle_signal);
    signal(SIGINT, handle_signal);
    signal(SIGHUP, handle_signal);

    unsigned long long last_rx = 0, last_tx = 0;
    get_net_bytes(&last_rx, &last_tx);

    unsigned long long last_cpu_total = 0, last_cpu_idle = 0;
    get_cpu_times(&last_cpu_total, &last_cpu_idle);

    double last_time = get_time_sec();

    char down_str[32];
    char up_str[32];

    while (running) {
        struct timespec req = {1, 500000000}; // 1.5s
        nanosleep(&req, NULL);
        if (!running) break;

        double curr_time = get_time_sec();
        double dt = curr_time - last_time;
        if (dt < 0.1) dt = 0.1;

        unsigned long long curr_rx = 0, curr_tx = 0;
        get_net_bytes(&curr_rx, &curr_tx);

        double rx_speed = (curr_rx >= last_rx) ? ((double)(curr_rx - last_rx) / dt) : 0.0;
        double tx_speed = (curr_tx >= last_tx) ? ((double)(curr_tx - last_tx) / dt) : 0.0;

        format_speed(rx_speed, down_str, sizeof(down_str));
        format_speed(tx_speed, up_str, sizeof(up_str));

        unsigned long long curr_cpu_total = 0, curr_cpu_idle = 0;
        get_cpu_times(&curr_cpu_total, &curr_cpu_idle);

        double cpu_usage = 0.0;
        if (curr_cpu_total > last_cpu_total) {
            unsigned long long diff_total = curr_cpu_total - last_cpu_total;
            unsigned long long diff_idle = (curr_cpu_idle > last_cpu_idle) ? (curr_cpu_idle - last_cpu_idle) : 0;
            if (diff_total > diff_idle) {
                cpu_usage = ((double)(diff_total - diff_idle) / (double)diff_total) * 100.0;
            }
        }

        double mem_usage = 0.0, swap_usage = 0.0;
        get_memory_info(&mem_usage, &swap_usage);

        printf("{\"cpu\": %.1f, \"memory\": %.1f, \"swap\": %.1f, \"network\": {\"down\": \"%s\", \"up\": \"%s\"}}\n",
               cpu_usage, mem_usage, swap_usage, down_str, up_str);
        fflush(stdout);

        last_rx = curr_rx;
        last_tx = curr_tx;
        last_cpu_total = curr_cpu_total;
        last_cpu_idle = curr_cpu_idle;
        last_time = curr_time;
    }

    return 0;
}
