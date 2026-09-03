#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ctype.h>

#define MAX_APPS 512
#define CACHE_FILE "/tmp/quickshell_apps_cache.json"

static char default_app_icon[512] = "";

typedef struct {
    char name[128];
    char desktop_id[128];
    char exec[512];
    char icon[512];
    char raw_icon[128];
    char comment[256];
    char wm_class[128];
} DesktopApp;

static DesktopApp apps[MAX_APPS];
static int app_count = 0;

static void json_escape(const char *in, char *out, size_t out_sz) {
    size_t j = 0;
    for (size_t i = 0; in[i] && j + 2 < out_sz; i++) {
        if (in[i] == '"' || in[i] == '\\') {
            out[j++] = '\\';
            out[j++] = in[i];
        } else if (in[i] == '\n') {
            out[j++] = ' ';
        } else if ((unsigned char)in[i] >= 32) {
            out[j++] = in[i];
        }
    }
    out[j] = '\0';
}

static void clean_exec(const char *in, char *out, size_t out_sz) {
    size_t j = 0;
    for (size_t i = 0; in[i] && j + 1 < out_sz; i++) {
        if (in[i] == '%' && in[i + 1]) {
            i++; // skip %U, %f, etc.
            continue;
        }
        out[j++] = in[i];
    }
    out[j] = '\0';
    // trim trailing spaces
    while (j > 0 && isspace((unsigned char)out[j - 1])) {
        out[--j] = '\0';
    }
}

static int file_exists(const char *path) {
    return access(path, F_OK) == 0;
}

static void resolve_icon(const char *icon_name, char *out_path, size_t out_sz) {
    if (!icon_name || !icon_name[0]) {
        snprintf(out_path, out_sz, "%s", default_app_icon);
        return;
    }
    if (icon_name[0] == '/' && file_exists(icon_name)) {
        snprintf(out_path, out_sz, "%s", icon_name);
        return;
    }

    const char *dirs[] = {
        "/usr/share/pixmaps",
        "/usr/share/icons/hicolor/scalable/apps",
        "/usr/share/icons/hicolor/512x512/apps",
        "/usr/share/icons/hicolor/256x256/apps",
        "/usr/share/icons/hicolor/128x128/apps",
        "/usr/share/icons/hicolor/64x64/apps",
        "/usr/share/icons/hicolor/48x48/apps",
        "/usr/share/icons/hicolor/32x32/apps",
        NULL
    };

    const char *exts[] = {".svg", ".png", "", NULL};

    for (int d = 0; dirs[d]; d++) {
        for (int e = 0; exts[e]; e++) {
            char candidate[512];
            snprintf(candidate, sizeof(candidate), "%s/%s%s", dirs[d], icon_name, exts[e]);
            if (file_exists(candidate)) {
                snprintf(out_path, out_sz, "%s", candidate);
                return;
            }
        }
    }

    snprintf(out_path, out_sz, "%s", default_app_icon);
}

static void parse_desktop_file(const char *filepath, const char *filename) {
    FILE *f = fopen(filepath, "r");
    if (!f) return;

    char line[1024];
    int in_entry = 0;
    int is_app = 0;
    int no_display = 0;
    int terminal = 0;

    char name[128] = {0};
    char exec[512] = {0};
    char icon[128] = {0};
    char comment[256] = {0};
    char wmclass[128] = {0};

    while (fgets(line, sizeof(line), f)) {
        char *p = line;
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '[') {
            if (strncmp(p, "[Desktop Entry]", 15) == 0) in_entry = 1;
            else in_entry = 0;
            continue;
        }
        if (!in_entry) continue;

        size_t len = strlen(p);
        while (len > 0 && (p[len - 1] == '\n' || p[len - 1] == '\r')) p[--len] = '\0';

        if (strncmp(p, "Type=", 5) == 0) {
            if (strcmp(p + 5, "Application") == 0) is_app = 1;
        } else if (strncmp(p, "NoDisplay=", 10) == 0) {
            if (strcasecmp(p + 10, "true") == 0 || strcmp(p + 10, "1") == 0) no_display = 1;
        } else if (strncmp(p, "Terminal=", 9) == 0) {
            if (strcasecmp(p + 9, "true") == 0 || strcmp(p + 9, "1") == 0) terminal = 1;
        } else if (strncmp(p, "Name=", 5) == 0 && !name[0]) {
            strncpy(name, p + 5, sizeof(name) - 1);
        } else if (strncmp(p, "Exec=", 5) == 0 && !exec[0]) {
            strncpy(exec, p + 5, sizeof(exec) - 1);
        } else if (strncmp(p, "Icon=", 5) == 0 && !icon[0]) {
            strncpy(icon, p + 5, sizeof(icon) - 1);
        } else if (strncmp(p, "Comment=", 8) == 0 && !comment[0]) {
            strncpy(comment, p + 8, sizeof(comment) - 1);
        } else if (strncmp(p, "StartupWMClass=", 15) == 0 && !wmclass[0]) {
            strncpy(wmclass, p + 15, sizeof(wmclass) - 1);
        }
    }
    fclose(f);

    if (!is_app || no_display || !name[0] || !exec[0]) return;

    for (int i = 0; i < app_count; i++) {
        if (strcasecmp(apps[i].name, name) == 0) return;
    }

    if (app_count < MAX_APPS) {
        DesktopApp *a = &apps[app_count];
        snprintf(a->name, sizeof(a->name), "%s", name);

        char clean_id[128];
        snprintf(clean_id, sizeof(clean_id), "%s", filename);
        char *dot = strstr(clean_id, ".desktop");
        if (dot) *dot = '\0';
        snprintf(a->desktop_id, sizeof(a->desktop_id), "%s", clean_id);

        char cleaned_cmd[512];
        clean_exec(exec, cleaned_cmd, sizeof(cleaned_cmd));
        if (terminal) {
            snprintf(a->exec, sizeof(a->exec), "kitty -e %.480s", cleaned_cmd);
        } else {
            snprintf(a->exec, sizeof(a->exec), "%s", cleaned_cmd);
        }

        snprintf(a->raw_icon, sizeof(a->raw_icon), "%s", icon);
        resolve_icon(icon, a->icon, sizeof(a->icon));
        snprintf(a->comment, sizeof(a->comment), "%s", comment);
        snprintf(a->wm_class, sizeof(a->wm_class), "%s", wmclass);
        app_count++;
    }
}

static void scan_dir(const char *dirpath) {
    DIR *d = opendir(dirpath);
    if (!d) return;

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        size_t nlen = strlen(ent->d_name);
        if (nlen > 8 && strcmp(ent->d_name + nlen - 8, ".desktop") == 0) {
            char fpath[1024];
            snprintf(fpath, sizeof(fpath), "%s/%s", dirpath, ent->d_name);
            parse_desktop_file(fpath, ent->d_name);
        }
    }
    closedir(d);
}

static int compare_names(const void *a, const void *b) {
    const DesktopApp *aa = (const DesktopApp *)a;
    const DesktopApp *bb = (const DesktopApp *)b;
    return strcasecmp(aa->name, bb->name);
}

int main(void) {
    const char *home = getenv("HOME");
    if (home) {
        snprintf(default_app_icon, sizeof(default_app_icon), "%s/.config/qs/assets/icons/system/default-app.svg", home);
    }

    char user_apps[512];
    if (home) {
        snprintf(user_apps, sizeof(user_apps), "%s/.local/share/applications", home);
        scan_dir(user_apps);
    }
    scan_dir("/usr/share/applications");
    scan_dir("/usr/local/share/applications");

    qsort(apps, app_count, sizeof(DesktopApp), compare_names);

    printf("[");
    for (int i = 0; i < app_count; i++) {
        char esc_name[256], esc_exec[1024], esc_icon[1024], esc_comment[512], esc_wm[256];
        json_escape(apps[i].name, esc_name, sizeof(esc_name));
        json_escape(apps[i].exec, esc_exec, sizeof(esc_exec));
        json_escape(apps[i].icon, esc_icon, sizeof(esc_icon));
        json_escape(apps[i].comment, esc_comment, sizeof(esc_comment));
        json_escape(apps[i].wm_class, esc_wm, sizeof(esc_wm));

        printf("%s{\"name\":\"%s\",\"desktopId\":\"%s\",\"exec\":\"%s\",\"icon\":\"%s\",\"rawIcon\":\"%s\",\"comment\":\"%s\",\"categories\":[\"Utilities\"],\"wmClass\":\"%s\"}",
               (i > 0 ? "," : ""),
               esc_name, apps[i].desktop_id, esc_exec, esc_icon, apps[i].raw_icon, esc_comment, esc_wm);
    }
    printf("]\n");
    return 0;
}
