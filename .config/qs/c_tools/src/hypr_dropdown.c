#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <poll.h>
#include <time.h>

static int connect_hypr_socket(const char *sock_name) {
    const char *xdg = getenv("XDG_RUNTIME_DIR");
    const char *his = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!xdg || !his) return -1;

    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/hypr/%s/%s", xdg, his, sock_name);

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

static char *hypr_query(const char *cmd) {
    int fd = connect_hypr_socket(".socket.sock");
    if (fd < 0) return NULL;

    if (write(fd, cmd, strlen(cmd)) < 0) {
        close(fd);
        return NULL;
    }

    size_t cap = 8192, len = 0;
    char *res = malloc(cap);
    if (!res) { close(fd); return NULL; }

    ssize_t n;
    while ((n = read(fd, res + len, cap - len - 1)) > 0) {
        len += n;
        if (len + 4096 >= cap) {
            cap *= 2;
            char *new_res = realloc(res, cap);
            if (!new_res) { free(res); close(fd); return NULL; }
            res = new_res;
        }
    }
    res[len] = '\0';
    close(fd);
    return res;
}

static void hypr_dispatch(const char *cmd) {
    int fd = connect_hypr_socket(".socket.sock");
    if (fd < 0) return;

    (void)write(fd, cmd, strlen(cmd));
    char d[128];
    while (read(fd, d, sizeof(d)) > 0) {}
    close(fd);
}

static int is_kitty_running(void) {
    char *clients = hypr_query("j/clients");
    if (!clients) return 0;
    int found = (strstr(clients, "\"kitty-dropdown\"") != NULL);
    free(clients);
    return found;
}

static int is_dropdown_active(void) {
    char *mons = hypr_query("j/monitors");
    if (!mons) return 0;
    int found = (strstr(mons, "special:dropdown") != NULL);
    free(mons);
    return found;
}

static void wait_for_dropdown_window(int socket2_fd, int timeout_ms) {
    if (socket2_fd < 0) return;
    struct pollfd pfd = { .fd = socket2_fd, .events = POLLIN };
    char buf[2048];
    int elapsed = 0;
    while (elapsed < timeout_ms) {
        int ret = poll(&pfd, 1, 30);
        if (ret > 0 && (pfd.revents & POLLIN)) {
            ssize_t n = read(socket2_fd, buf, sizeof(buf) - 1);
            if (n > 0) {
                buf[n] = '\0';
                if (strstr(buf, "openwindow") && strstr(buf, "kitty-dropdown")) {
                    break;
                }
            }
        }
        elapsed += 30;
    }
}

static void spawn_kitty_dropdown(void) {
    pid_t pid = fork();
    if (pid == 0) {
        setsid();
        int devnull = open("/dev/null", O_RDWR);
        if (devnull >= 0) {
            dup2(devnull, STDIN_FILENO);
            dup2(devnull, STDOUT_FILENO);
            dup2(devnull, STDERR_FILENO);
            close(devnull);
        }
        char *args[] = {
            "kitty",
            "--class", "kitty-dropdown",
            "-o", "background_opacity=1.0",
            "-o", "background_blur=0",
            NULL
        };
        execvp("kitty", args);
        _exit(1);
    }
}

static int is_debounced(void) {
    char p[256];
    const char *xdg = getenv("XDG_RUNTIME_DIR");
    snprintf(p, sizeof(p), "%s/hypr_dropdown.last", xdg ? xdg : "/tmp");

    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    long long now_ms = (long long)now.tv_sec * 1000 + now.tv_nsec / 1000000;

    FILE *f = fopen(p, "r");
    if (f) {
        long long last = 0;
        if (fscanf(f, "%lld", &last) == 1 && (now_ms - last < 120)) {
            fclose(f);
            return 1;
        }
        fclose(f);
    }
    f = fopen(p, "w");
    if (f) {
        fprintf(f, "%lld\n", now_ms);
        fclose(f);
    }
    return 0;
}

int main(void) {
    if (is_debounced()) return 0;

    int running = is_kitty_running();
    int spawned = 0;

    if (!running) {
        int s2 = connect_hypr_socket(".socket2.sock");
        spawn_kitty_dropdown();
        spawned = 1;
        wait_for_dropdown_window(s2, 1000);
        if (s2 >= 0) close(s2);
        usleep(20000); // 20ms to settle
    }

    // Ensure decorations are configured without special dimming/blur
    hypr_dispatch("eval hl.config({ decoration = { dim_special = 0.0, blur = { special = false } } })");

    if (spawned) {
        if (!is_dropdown_active()) {
            hypr_dispatch("dispatch hl.dsp.workspace.toggle_special('dropdown')");
        }
    } else {
        hypr_dispatch("dispatch hl.dsp.workspace.toggle_special('dropdown')");
    }

    return 0;
}
