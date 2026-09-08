#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>

typedef struct {
    char address[32];
    char class_name[128];
    char title[256];
    int focusHistoryID;
    int ws_id;
    int hidden;
} Client;

static int connect_hypr_socket(void) {
    const char *xdg = getenv("XDG_RUNTIME_DIR");
    const char *his = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!xdg || !his) return -1;

    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/hypr/%s/.socket.sock", xdg, his);

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        close(fd);
        return -1;
    }
    return fd;
}

static char *hypr_query(const char *cmd) {
    int fd = connect_hypr_socket();
    if (fd < 0) return NULL;

    if (write(fd, cmd, strlen(cmd)) < 0) {
        close(fd);
        return NULL;
    }

    size_t cap = 16384, len = 0;
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

static void focus_window(const char *addr) {
    int fd = connect_hypr_socket();
    if (fd < 0) return;
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
             "eval hl.dispatch(hl.dsp.focus({ window = 'address:%.32s' })); hl.dispatch(hl.dsp.window.alter_zorder({ mode = 'top', window = 'address:%.32s' }))",
             addr, addr);
    (void)write(fd, cmd, strlen(cmd));
    char d[128];
    while (read(fd, d, sizeof(d)) > 0) {}
    close(fd);
}

static int get_active_workspace(void) {
    char *raw = hypr_query("j/activeworkspace");
    if (!raw) return 1;
    const char *p = strstr(raw, "\"id\":");
    int id = 1;
    if (p) id = atoi(p + 5);
    free(raw);
    return id;
}

static int compare_clients(const void *a, const void *b) {
    const Client *ca = (const Client *)a;
    const Client *cb = (const Client *)b;
    return ca->focusHistoryID - cb->focusHistoryID;
}

/* Micro JSON string extractor */
static void j_extract_str(const char *json, const char *key, char *out, size_t max_len) {
    out[0] = '\0';
    char pat[64];
    snprintf(pat, sizeof(pat), "\"%s\":", key);
    const char *p = strstr(json, pat);
    if (!p) return;
    p += strlen(pat);
    while (*p == ' ' || *p == '\t') p++;
    if (*p != '"') return;
    p++;
    const char *end = strchr(p, '"');
    if (!end) return;
    size_t len = (size_t)(end - p);
    if (len >= max_len) len = max_len - 1;
    strncpy(out, p, len);
    out[len] = '\0';
}

static int j_extract_int(const char *json, const char *key, int default_val) {
    char pat[64];
    snprintf(pat, sizeof(pat), "\"%s\":", key);
    const char *p = strstr(json, pat);
    if (!p) return default_val;
    p += strlen(pat);
    while (*p == ' ' || *p == '\t') p++;
    return atoi(p);
}

static int j_extract_bool(const char *json, const char *key) {
    char pat[64];
    snprintf(pat, sizeof(pat), "\"%s\":", key);
    const char *p = strstr(json, pat);
    if (!p) return 0;
    p += strlen(pat);
    while (*p == ' ' || *p == '\t') p++;
    return (strncmp(p, "true", 4) == 0);
}

/* Escape string for JSON output */
static void print_json_escaped(const char *s) {
    while (*s) {
        if (*s == '"') printf("\\\"");
        else if (*s == '\\') printf("\\\\");
        else if (*s == '\n') printf("\\n");
        else if (*s == '\r') printf("\\r");
        else if (*s == '\t') printf("\\t");
        else putchar(*s);
        s++;
    }
}

static void get_browser_title(const char *needle) {
    char *clients_raw = hypr_query("j/clients");
    if (!clients_raw) return;

    const char *p = clients_raw;
    while ((p = strstr(p, "\"address\":")) != NULL) {
        const char *next = strstr(p + 10, "\"address\":");
        const char *obj_end = next ? next : (p + strlen(p));

        char blk[4096];
        size_t len = (size_t)(obj_end - p);
        if (len >= sizeof(blk)) len = sizeof(blk) - 1;
        strncpy(blk, p, len);
        blk[len] = '\0';

        char cls[128];
        j_extract_str(blk, "class", cls, sizeof(cls));
        if (strcasestr(cls, needle)) {
            char title[256];
            j_extract_str(blk, "title", title, sizeof(title));
            printf("%s\n", title);
            free(clients_raw);
            return;
        }
        p = obj_end;
    }
    free(clients_raw);
}

int main(int argc, char **argv) {
    if (argc > 2 && strcmp(argv[1], "focus") == 0) {
        focus_window(argv[2]);
        return 0;
    }
    if (argc > 2 && strcmp(argv[1], "title") == 0) {
        get_browser_title(argv[2]);
        return 0;
    }

    int active_ws = get_active_workspace();
    char *clients_raw = hypr_query("j/clients");
    if (!clients_raw) {
        printf("[]\n");
        return 0;
    }

    Client list[128];
    int count = 0;

    const char *p = clients_raw;
    while ((p = strstr(p, "\"address\":")) != NULL && count < 128) {
        const char *next = strstr(p + 10, "\"address\":");
        const char *obj_end = next ? next : (p + strlen(p));

        char blk[4096];
        size_t len = (size_t)(obj_end - p);
        if (len >= sizeof(blk)) len = sizeof(blk) - 1;
        strncpy(blk, p, len);
        blk[len] = '\0';

        // Check workspace
        const char *wsp = strstr(blk, "\"workspace\":");
        int ws = wsp ? j_extract_int(wsp, "id", -999) : -999;
        int hidden = j_extract_bool(blk, "hidden");

        if (ws == active_ws && !hidden) {
            j_extract_str(blk, "address", list[count].address, sizeof(list[count].address));
            j_extract_str(blk, "class", list[count].class_name, sizeof(list[count].class_name));
            j_extract_str(blk, "title", list[count].title, sizeof(list[count].title));
            list[count].focusHistoryID = j_extract_int(blk, "focusHistoryID", 999);
            list[count].ws_id = ws;
            list[count].hidden = hidden;
            count++;
        }
        p = obj_end;
    }
    free(clients_raw);

    if (count > 1) {
        qsort(list, count, sizeof(Client), compare_clients);
    }

    printf("[");
    for (int i = 0; i < count; i++) {
        printf("%s{\"address\":\"%s\",\"class\":\"", i > 0 ? "," : "", list[i].address);
        print_json_escaped(list[i].class_name);
        printf("\",\"title\":\"");
        print_json_escaped(list[i].title);
        printf("\",\"focusHistoryID\":%d,\"workspace\":{\"id\":%d}}", list[i].focusHistoryID, list[i].ws_id);
    }
    printf("]\n");

    return 0;
}
