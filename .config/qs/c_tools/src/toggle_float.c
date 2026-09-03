#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <time.h>

#define MAX_CACHE 512
#define CLAMP(v, min, max) ((v) < (min) ? (min) : ((v) > (max) ? (max) : (v)))

typedef struct { char key[96]; int w, h, x, y; } CacheEntry;
typedef struct { char addr[32], cls[64], title[128]; int float_st, w, h, x, y, grp; } Win;

static CacheEntry cache[MAX_CACHE];
static int cache_sz = 0;

/* Hyprland Socket IPC (Dual-mode: Query if query_cmd != NULL, Eval if eval_lua != NULL) */
static char *hypr_ipc(const char *query_cmd, const char *eval_lua) {
    const char *xdg = getenv("XDG_RUNTIME_DIR"), *his = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!xdg || !his) return NULL;

    struct sockaddr_un addr = { .sun_family = AF_UNIX };
    snprintf(addr.sun_path, sizeof(addr.sun_path), "%s/hypr/%s/.socket.sock", xdg, his);

    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0 || connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
        if (fd >= 0) close(fd);
        return NULL;
    }

    if (eval_lua) {
        size_t len = strlen(eval_lua);
        char *buf = malloc(len + 8);
        if (buf) {
            snprintf(buf, len + 8, "eval %s", eval_lua);
            (void)write(fd, buf, strlen(buf));
            free(buf);
        }
        char d[128];
        while (read(fd, d, sizeof(d)) > 0) {}
        close(fd);
        return NULL;
    }

    (void)write(fd, query_cmd, strlen(query_cmd));
    size_t cap = 8192, len = 0;
    char *res = malloc(cap);
    ssize_t n;
    while ((n = read(fd, res + len, cap - len - 1)) > 0) {
        len += n;
        if (len + 4096 >= cap) {
            cap *= 2;
            res = realloc(res, cap);
        }
    }
    res[len] = '\0';
    close(fd);
    return res;
}

/* Micro JSON Parser */
static int j_str(const char *j, const char *k, char *out, size_t sz) {
    char pat[64]; snprintf(pat, sizeof(pat), "\"%s\"", k);
    const char *p = strstr(j, pat);
    if (!p || !(p = strchr(p + strlen(pat), ':'))) return 0;
    p++; while (*p == ' ' || *p == '\t' || *p == '\n') p++;
    if (*p != '"') return 0;
    p++; const char *end = strchr(p, '"');
    if (!end) return 0;
    size_t len = (size_t)(end - p) >= sz ? sz - 1 : (size_t)(end - p);
    strncpy(out, p, len); out[len] = '\0';
    return 1;
}

static int j_int(const char *j, const char *k) {
    char pat[64]; snprintf(pat, sizeof(pat), "\"%s\"", k);
    const char *p = strstr(j, pat);
    if (!p || !(p = strchr(p + strlen(pat), ':'))) return 0;
    p++; while (*p == ' ' || *p == '\t' || *p == '\n') p++;
    return atoi(p);
}

static int j_bool(const char *j, const char *k) {
    char pat[64]; snprintf(pat, sizeof(pat), "\"%s\"", k);
    const char *p = strstr(j, pat);
    if (!p || !(p = strchr(p + strlen(pat), ':'))) return 0;
    p++; while (*p == ' ' || *p == '\t' || *p == '\n') p++;
    return strncmp(p, "true", 4) == 0;
}

static int j_pair(const char *j, const char *k, int *v1, int *v2) {
    char pat[64]; snprintf(pat, sizeof(pat), "\"%s\"", k);
    const char *p = strstr(j, pat);
    if (!p || !(p = strchr(p + strlen(pat), '['))) return 0;
    p++; *v1 = atoi(p);
    if (!(p = strchr(p, ','))) return 0;
    p++; *v2 = atoi(p);
    return 1;
}

/* Geometry Cache */
static void get_cache_path(char *out, size_t sz) {
    const char *home = getenv("HOME");
    snprintf(out, sz, "%s/.cache/hypr_float_geometry.json", home ? home : "/tmp");
}

static void cache_load(void) {
    char p[256]; get_cache_path(p, sizeof(p));
    FILE *f = fopen(p, "r");
    if (!f) return;
    char l[256]; cache_sz = 0;
    while (fgets(l, sizeof(l), f) && cache_sz < MAX_CACHE) {
        char *q1 = strchr(l, '"'), *pw = strstr(l, "\"w\":"), *ph = strstr(l, "\"h\":"),
             *px = strstr(l, "\"x\":"), *py = strstr(l, "\"y\":");
        if (!q1 || !pw || !ph || !px || !py) continue;
        char *q2 = strchr(q1 + 1, '"');
        if (!q2) continue;
        size_t kl = (size_t)(q2 - q1 - 1);
        if (kl >= sizeof(cache[cache_sz].key)) kl = sizeof(cache[cache_sz].key) - 1;
        strncpy(cache[cache_sz].key, q1 + 1, kl);
        cache[cache_sz].key[kl] = '\0';
        cache[cache_sz].w = atoi(pw + 4); cache[cache_sz].h = atoi(ph + 4);
        cache[cache_sz].x = atoi(px + 4); cache[cache_sz].y = atoi(py + 4);
        if (cache[cache_sz].w > 0 && cache[cache_sz].h > 0) cache_sz++;
    }
    fclose(f);
}

static void cache_save(void) {
    char p[256]; get_cache_path(p, sizeof(p));
    FILE *f = fopen(p, "w");
    if (!f) return;
    fprintf(f, "{\n");
    for (int i = 0; i < cache_sz; i++) {
        fprintf(f, "  \"%s\": {\"w\": %d, \"h\": %d, \"x\": %d, \"y\": %d}%s\n",
                cache[i].key, cache[i].w, cache[i].h, cache[i].x, cache[i].y,
                (i + 1 < cache_sz) ? "," : "");
    }
    fprintf(f, "}\n");
    fclose(f);
}

static int cache_get(const char *key, int *w, int *h, int *x, int *y) {
    if (!key || !*key) return 0;
    for (int i = 0; i < cache_sz; i++) {
        if (strcmp(cache[i].key, key) == 0) {
            *w = cache[i].w; *h = cache[i].h; *x = cache[i].x; *y = cache[i].y;
            return 1;
        }
    }
    return 0;
}

static void cache_set(const char *key, int w, int h, int x, int y) {
    if (!key || !*key || w <= 0 || h <= 0) return;
    for (int i = 0; i < cache_sz; i++) {
        if (strcmp(cache[i].key, key) == 0) {
            cache[i].w = w; cache[i].h = h; cache[i].x = x; cache[i].y = y;
            return;
        }
    }
    if (cache_sz < MAX_CACHE) {
        snprintf(cache[cache_sz].key, sizeof(cache[cache_sz].key), "%s", key);
        cache[cache_sz].w = w; cache[cache_sz].h = h; cache[cache_sz].x = x; cache[cache_sz].y = y;
        cache_sz++;
    }
}

static void get_monitor(int mid, int *mx, int *my, int *mw, int *mh) {
    *mx = 0; *my = 0; *mw = 1920; *mh = 1080;
    char *mons = hypr_ipc("j/monitors", NULL);
    if (!mons) return;
    const char *p = mons;
    while ((p = strstr(p, "\"id\":")) != NULL) {
        int id = j_int(p, "id"), foc = j_bool(p, "focused");
        if ((mid >= 0 && id == mid) || (mid < 0 && foc)) {
            *mx = j_int(p, "x"); *my = j_int(p, "y");
            *mw = j_int(p, "width"); *mh = j_int(p, "height");
            break;
        }
        p += 5;
    }
    free(mons);
}

/* Toggle Single Active Window */
static void toggle_single(void) {
    char *win = hypr_ipc("j/activewindow", NULL);
    if (!win || !strstr(win, "\"address\"")) { free(win); return; }

    Win w = {0};
    j_str(win, "address", w.addr, sizeof(w.addr));
    j_str(win, "class", w.cls, sizeof(w.cls));
    j_str(win, "title", w.title, sizeof(w.title));
    w.float_st = j_bool(win, "floating");
    j_pair(win, "size", &w.w, &w.h);
    j_pair(win, "at", &w.x, &w.y);

    const char *grp_ptr = strstr(win, "\"grouped\"");
    if (grp_ptr && (grp_ptr = strchr(grp_ptr, '['))) {
        for (const char *c = grp_ptr + 1; *c && *c != ']'; c++) if (*c == '"') { w.grp++; c = strchr(c + 1, '"'); if (!c) break; }
    }

    int mid = j_int(win, "monitor");
    free(win);
    cache_load();

    char id_key[192]; snprintf(id_key, sizeof(id_key), "%s:%s", w.cls, w.title);
    int mx, my, mw, mh; get_monitor(mid, &mx, &my, &mw, &mh);

    if (w.float_st) {
        cache_set(w.addr, w.w, w.h, w.x, w.y);
        cache_set(w.cls, w.w, w.h, w.x, w.y);
        cache_set(id_key, w.w, w.h, w.x, w.y);
        cache_save();

        char cmd[128];
        snprintf(cmd, sizeof(cmd), "hl.dispatch(hl.dsp.window.float({ window = \"address:%.32s\", action = \"off\" }))", w.addr);
        hypr_ipc(NULL, cmd);
    } else {
        char lua[1024] = {0};
        if (w.grp > 1) strcat(lua, "hl.dispatch(hl.dsp.group.toggle())\n");

        int fw = 0, fh = 0, fx = 0, fy = 0;
        int has_geo = cache_get(w.addr, &fw, &fh, &fx, &fy) || cache_get(w.cls, &fw, &fh, &fx, &fy) || cache_get(id_key, &fw, &fh, &fx, &fy);

        if (has_geo && fw > 0 && fh > 0) {
            fw = CLAMP(fw, 450, mw - 40); fh = CLAMP(fh, 350, mh - 70);
            fx = CLAMP(fx, mx + 20, mx + mw - fw - 20); fy = CLAMP(fy, my + 45, my + mh - fh - 20);
        } else {
            fw = CLAMP((int)(mw * 0.68), 750, 1350); fh = CLAMP((int)(mh * 0.68), 500, 850);
            fx = mx + (mw - fw) / 2; fy = my + (mh - fh) / 2;
        }

        char step[512];
        snprintf(step, sizeof(step),
                 "hl.dispatch(hl.dsp.window.float({ window = \"address:%s\", action = \"on\" }))\n"
                 "hl.dispatch(hl.dsp.window.resize({ window = \"address:%s\", x = %d, y = %d, relative = false }))\n"
                 "hl.dispatch(hl.dsp.window.move({ window = \"address:%s\", x = %d, y = %d, relative = false }))\n"
                 "hl.dispatch(hl.dsp.focus({ window = \"address:%s\" }))\n",
                 w.addr, w.addr, fw, fh, w.addr, fx, fy, w.addr);
        strcat(lua, step);
        hypr_ipc(NULL, lua);
    }
}

/* Toggle All Windows on Workspace (Cascade) */
static void toggle_all(void) {
    char *ws_raw = hypr_ipc("j/activeworkspace", NULL);
    if (!ws_raw) return;
    int target_ws = j_int(ws_raw, "id");
    free(ws_raw);

    char *clients_raw = hypr_ipc("j/clients", NULL);
    if (!clients_raw) return;

    Win wins[64]; int cnt = 0, any_tiled = 0;
    const char *p = clients_raw;
    while ((p = strstr(p, "\"address\":")) != NULL && cnt < 64) {
        const char *obj_end = strchr(p, '}');
        if (!obj_end) break;
        char blk[1500]; size_t blk_len = (size_t)(obj_end - p + 1);
        if (blk_len >= sizeof(blk)) blk_len = sizeof(blk) - 1;
        strncpy(blk, p, blk_len); blk[blk_len] = '\0';

        const char *wsp = strstr(blk, "\"workspace\":");
        if (wsp && j_int(wsp, "id") == target_ws && !j_bool(blk, "hidden")) {
            j_str(blk, "address", wins[cnt].addr, sizeof(wins[cnt].addr));
            j_str(blk, "class", wins[cnt].cls, sizeof(wins[cnt].cls));
            j_str(blk, "title", wins[cnt].title, sizeof(wins[cnt].title));
            wins[cnt].float_st = j_bool(blk, "floating");
            j_pair(blk, "size", &wins[cnt].w, &wins[cnt].h);
            j_pair(blk, "at", &wins[cnt].x, &wins[cnt].y);
            if (!wins[cnt].float_st) any_tiled = 1;
            cnt++;
        }
        p = obj_end + 1;
    }
    free(clients_raw);
    if (cnt == 0) return;

    cache_load();
    int mx, my, mw, mh; get_monitor(-1, &mx, &my, &mw, &mh);
    char lua[16384] = {0};

    if (any_tiled) {
        int def_w = CLAMP((int)(mw * (cnt == 1 ? 0.70 : 0.62)), 780, 1300);
        int def_h = CLAMP((int)(mh * (cnt == 1 ? 0.70 : 0.64)), 520, 820);
        int anc[7][2] = {
            { mx + 35, my + 55 }, { mx + mw - def_w - 35, my + mh - def_h - 30 },
            { mx + mw - def_w - 35, my + 55 }, { mx + 35, my + mh - def_h - 30 },
            { mx + (mw - def_w)/2, my + 55 }, { mx + (mw - def_w)/2, my + mh - def_h - 30 },
            { mx + (mw - def_w)/2, my + (mh - def_h)/2 }
        };

        for (int i = 0; i < cnt; i++) {
            char id_k[192]; snprintf(id_k, sizeof(id_k), "%s:%s", wins[i].cls, wins[i].title);
            int fw = 0, fh = 0, fx = 0, fy = 0;
            int has = cache_get(wins[i].addr, &fw, &fh, &fx, &fy) || cache_get(wins[i].cls, &fw, &fh, &fx, &fy) || cache_get(id_k, &fw, &fh, &fx, &fy);

            if (has && fw > 0 && fh > 0) {
                fw = CLAMP(fw, 450, mw - 40); fh = CLAMP(fh, 350, mh - 70);
                fx = CLAMP(fx, mx + 20, mx + mw - fw - 20); fy = CLAMP(fy, my + 45, my + mh - fh - 20);
            } else {
                fw = def_w; fh = def_h;
                int a = i % 7, cyc = i / 7;
                fx = CLAMP(anc[a][0] + (cyc * 45), mx + 20, mx + mw - def_w - 20);
                fy = CLAMP(anc[a][1] + (cyc * 35), my + 45, my + mh - def_h - 20);
            }

            char step[512];
            snprintf(step, sizeof(step),
                     "hl.dispatch(hl.dsp.window.float({ window = \"address:%.32s\", action = \"on\" }))\n"
                     "hl.dispatch(hl.dsp.window.resize({ window = \"address:%.32s\", x = %d, y = %d, relative = false }))\n"
                     "hl.dispatch(hl.dsp.window.move({ window = \"address:%.32s\", x = %d, y = %d, relative = false }))\n",
                     wins[i].addr, wins[i].addr, fw, fh, wins[i].addr, fx, fy);
            strcat(lua, step);
        }
        char foc[128]; snprintf(foc, sizeof(foc), "hl.dispatch(hl.dsp.focus({ window = \"address:%.32s\" }))\n", wins[cnt - 1].addr);
        strcat(lua, foc);
    } else {
        for (int i = 0; i < cnt; i++) {
            char id_k[192]; snprintf(id_k, sizeof(id_k), "%s:%s", wins[i].cls, wins[i].title);
            cache_set(wins[i].addr, wins[i].w, wins[i].h, wins[i].x, wins[i].y);
            cache_set(wins[i].cls, wins[i].w, wins[i].h, wins[i].x, wins[i].y);
            cache_set(id_k, wins[i].w, wins[i].h, wins[i].x, wins[i].y);

            char step[128];
            snprintf(step, sizeof(step), "hl.dispatch(hl.dsp.window.float({ window = \"address:%.32s\", action = \"off\" }))\n", wins[i].addr);
            strcat(lua, step);
        }
        cache_save();
    }
    hypr_ipc(NULL, lua);
}

/* 180ms Debouncer & Entry Point */
static int is_debounced(void) {
    char p[256]; const char *xdg = getenv("XDG_RUNTIME_DIR");
    snprintf(p, sizeof(p), "%s/toggle_float.last", xdg ? xdg : "/tmp");

    struct timespec now; clock_gettime(CLOCK_MONOTONIC, &now);
    long long now_ms = (long long)now.tv_sec * 1000 + now.tv_nsec / 1000000;

    FILE *f = fopen(p, "r");
    if (f) {
        long long last = 0;
        if (fscanf(f, "%lld", &last) == 1 && (now_ms - last < 180)) { fclose(f); return 1; }
        fclose(f);
    }
    if ((f = fopen(p, "w"))) { fprintf(f, "%lld\n", now_ms); fclose(f); }
    return 0;
}

int main(int argc, char **argv) {
    if (is_debounced()) return 0;
    if (argc > 1 && strcmp(argv[1], "all") == 0) toggle_all();
    else toggle_single();
    return 0;
}
