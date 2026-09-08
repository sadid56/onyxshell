#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

static int has_valid_ext(const char *name) {
    const char *dot = strrchr(name, '.');
    if (!dot) return 0;
    return (strcasecmp(dot, ".jpg") == 0 ||
            strcasecmp(dot, ".jpeg") == 0 ||
            strcasecmp(dot, ".png") == 0 ||
            strcasecmp(dot, ".webp") == 0 ||
            strcasecmp(dot, ".gif") == 0);
}

static void scan_dir(const char *dir_path, int depth) {
    if (depth > 2) return;
    DIR *d = opendir(dir_path);
    if (!d) return;

    struct dirent *ent;
    while ((ent = readdir(d)) != NULL) {
        if (ent->d_name[0] == '.') continue;

        char full[1024];
        snprintf(full, sizeof(full), "%s/%s", dir_path, ent->d_name);

        struct stat st;
        if (stat(full, &st) == 0) {
            if (S_ISDIR(st.st_mode)) {
                scan_dir(full, depth + 1);
            } else if (S_ISREG(st.st_mode) && has_valid_ext(ent->d_name)) {
                printf("%s\n", full);
            }
        }
    }
    closedir(d);
}

int main(int argc, char **argv) {
    char dir[1024];
    if (argc > 1 && argv[1][0] != '\0') {
        strncpy(dir, argv[1], sizeof(dir) - 1);
        dir[sizeof(dir) - 1] = '\0';
    } else {
        const char *home = getenv("HOME");
        snprintf(dir, sizeof(dir), "%s/Pictures/wallpapers", home ? home : "/tmp");
    }

    scan_dir(dir, 1);
    return 0;
}
