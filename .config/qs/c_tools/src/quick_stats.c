#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <sys/types.h>

static void get_uptime(void) {
    FILE *f = fopen("/proc/uptime", "r");
    if (!f) return;
    double sec = 0;
    if (fscanf(f, "%lf", &sec) == 1) {
        long s = (long)sec;
        long d = s / 86400;
        long h = (s % 86400) / 3600;
        long m = (s % 3600) / 60;
        if (d > 0) {
            printf("UP: up %ld day%s, %ld hour%s, %ld minute%s\n",
                   d, d > 1 ? "s" : "", h, h > 1 ? "s" : "", m, m > 1 ? "s" : "");
        } else if (h > 0) {
            printf("UP: up %ld hour%s, %ld minute%s\n",
                   h, h > 1 ? "s" : "", m, m > 1 ? "s" : "");
        } else {
            printf("UP: up %ld minute%s\n", m, m > 1 ? "s" : "");
        }
    }
    fclose(f);
}

static void get_brightness(void) {
    DIR *d = opendir("/sys/class/backlight");
    if (!d) return;
    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;
        char path_cur[512], path_max[512];
        snprintf(path_cur, sizeof(path_cur), "/sys/class/backlight/%s/brightness", ent->d_name);
        snprintf(path_max, sizeof(path_max), "/sys/class/backlight/%s/max_brightness", ent->d_name);
        FILE *fc = fopen(path_cur, "r"), *fm = fopen(path_max, "r");
        if (fc && fm) {
            int cur = 0, max = 0;
            if (fscanf(fc, "%d", &cur) == 1 && fscanf(fm, "%d", &max) == 1 && max > 0) {
                int pct = (int)((cur * 100.0 / max) + 0.5);
                printf("BRI: %s,backlight,%d,%d%%,%d\n", ent->d_name, cur, pct, max);
                fclose(fc);
                fclose(fm);
                break;
            }
        }
        if (fc) fclose(fc);
        if (fm) fclose(fm);
    }
    closedir(d);
}

static void get_wifi(void) {
    DIR *d = opendir("/sys/class/rfkill");
    int found = 0;
    if (d) {
        struct dirent *ent;
        while ((ent = readdir(d)) != NULL) {
            if (ent->d_name[0] == '.') continue;
            char path_type[512], path_state[512];
            snprintf(path_type, sizeof(path_type), "/sys/class/rfkill/%s/type", ent->d_name);
            snprintf(path_state, sizeof(path_state), "/sys/class/rfkill/%s/state", ent->d_name);
            FILE *ft = fopen(path_type, "r");
            if (ft) {
                char type[32] = {0};
                if (fgets(type, sizeof(type), ft) && strncmp(type, "wlan", 4) == 0) {
                    FILE *fs = fopen(path_state, "r");
                    if (fs) {
                        int state = 0;
                        if (fscanf(fs, "%d", &state) == 1) {
                            printf("WIFI: %s\n", state == 1 ? "enabled" : "disabled");
                            found = 1;
                        }
                        fclose(fs);
                    }
                }
                fclose(ft);
            }
            if (found) break;
        }
        closedir(d);
    }
    if (!found) {
        printf("WIFI: enabled\n");
    }
}

static int is_proc_running(const char *name) {
    DIR *d = opendir("/proc");
    if (!d) return 0;
    struct dirent *ent;
    int running = 0;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] < '0' || ent->d_name[0] > '9') continue;
        char path[512];
        snprintf(path, sizeof(path), "/proc/%s/comm", ent->d_name);
        FILE *f = fopen(path, "r");
        if (f) {
            char comm[64] = {0};
            if (fgets(comm, sizeof(comm), f)) {
                size_t l = strlen(comm);
                if (l > 0 && comm[l - 1] == '\n') comm[l - 1] = '\0';
                if (strcmp(comm, name) == 0) {
                    running = 1;
                    fclose(f);
                    break;
                }
            }
            fclose(f);
        }
    }
    closedir(d);
    return running;
}

static void get_nightlight(void) {
    const char *xdg = getenv("XDG_RUNTIME_DIR");
    const char *user = getenv("USER");
    char path[256];
    snprintf(path, sizeof(path), "%s/hyprsunset_%s.state", xdg ? xdg : "/tmp", user ? user : "user");
    if (access(path, F_OK) == 0 && is_proc_running("hyprsunset")) {
        printf("NIGHT: on\n");
    } else {
        printf("NIGHT: off\n");
    }
}

static void get_audio(void) {
    FILE *f1 = popen("wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null", "r");
    if (f1) {
        char buf[128];
        if (fgets(buf, sizeof(buf), f1)) {
            buf[strcspn(buf, "\r\n")] = 0;
            printf("VOL: %s\n", buf);
        }
        pclose(f1);
    }
    FILE *f2 = popen("wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null", "r");
    if (f2) {
        char buf[128];
        if (fgets(buf, sizeof(buf), f2)) {
            buf[strcspn(buf, "\r\n")] = 0;
            printf("MIC: %s\n", buf);
        }
        pclose(f2);
    }
}

static void get_powerprofile(void) {
    FILE *f = fopen("/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference", "r");
    if (f) {
        char buf[64] = {0};
        if (fgets(buf, sizeof(buf), f)) {
            fclose(f);
            if (strncmp(buf, "performance", 11) == 0) {
                printf("PPD: performance\n");
                return;
            } else if (strstr(buf, "power")) {
                printf("PPD: power-saver\n");
                return;
            } else if (strstr(buf, "balance")) {
                printf("PPD: balanced\n");
                return;
            }
        } else {
            fclose(f);
        }
    }
    FILE *fp = popen("powerprofilesctl get 2>/dev/null", "r");
    if (fp) {
        char buf[64];
        if (fgets(buf, sizeof(buf), fp)) {
            buf[strcspn(buf, "\r\n")] = 0;
            printf("PPD: %s\n", buf);
        }
        pclose(fp);
    }
}

int main(void) {
    get_audio();
    get_brightness();
    get_wifi();
    get_nightlight();
    get_powerprofile();
    get_uptime();
    return 0;
}
