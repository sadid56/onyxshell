#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define PREVIEW_DIR "/tmp/cliphist_previews"

static void copy_clip(const char *entry) {
    int in_pipe[2];
    int mid_pipe[2];
    if (pipe(in_pipe) < 0 || pipe(mid_pipe) < 0) return;

    if (fork() == 0) {
        close(in_pipe[1]);
        dup2(in_pipe[0], STDIN_FILENO);
        close(in_pipe[0]);

        close(mid_pipe[0]);
        dup2(mid_pipe[1], STDOUT_FILENO);
        close(mid_pipe[1]);

        execlp("cliphist", "cliphist", "decode", NULL);
        _exit(1);
    }
    close(in_pipe[0]);

    if (fork() == 0) {
        close(in_pipe[1]);
        close(mid_pipe[1]);
        dup2(mid_pipe[0], STDIN_FILENO);
        close(mid_pipe[0]);

        execlp("wl-copy", "wl-copy", NULL);
        _exit(1);
    }
    close(mid_pipe[0]);
    close(mid_pipe[1]);

    (void)write(in_pipe[1], entry, strlen(entry));
    close(in_pipe[1]);

    while (wait(NULL) > 0) {}
}

static void delete_clip(const char *entry) {
    int pfd[2];
    if (pipe(pfd) < 0) return;
    if (fork() == 0) {
        close(pfd[1]);
        dup2(pfd[0], STDIN_FILENO);
        close(pfd[0]);
        execlp("cliphist", "cliphist", "delete", NULL);
        _exit(1);
    }
    close(pfd[0]);
    (void)write(pfd[1], entry, strlen(entry));
    close(pfd[1]);

    while (wait(NULL) > 0) {}
}

int main(int argc, char **argv) {
    if (argc > 2 && strcmp(argv[1], "copy") == 0) {
        copy_clip(argv[2]);
        return 0;
    }
    if (argc > 2 && strcmp(argv[1], "delete") == 0) {
        delete_clip(argv[2]);
        return 0;
    }

    mkdir(PREVIEW_DIR, 0755);

    FILE *pipe = popen("cliphist list", "r");
    if (!pipe) {
        printf("{}\n");
        return 0;
    }

    char line[4096];
    int first = 1;
    printf("{");

    while (fgets(line, sizeof(line), pipe)) {
        size_t len = strlen(line);
        if (len > 0 && line[len - 1] == '\n') line[len - 1] = '\0';

        char *tab = strchr(line, '\t');
        if (!tab) continue;

        *tab = '\0';
        char *entry_id = line;
        char *content = tab + 1;

        if (strstr(content, "[[ binary data") || strstr(content, "[[binary data")) {
            const char *ext = "png";
            if (strstr(content, "jpg") || strstr(content, "jpeg")) ext = "jpg";
            else if (strstr(content, "webp")) ext = "webp";
            else if (strstr(content, "gif")) ext = "gif";

            char out_path[512];
            snprintf(out_path, sizeof(out_path), "%s/%s.%s", PREVIEW_DIR, entry_id, ext);

            if (access(out_path, F_OK) != 0) {
                char cmd[1024];
                snprintf(cmd, sizeof(cmd), "printf '%%s\\t%%s' '%s' '%s' | cliphist decode > '%s' 2>/dev/null",
                         entry_id, content, out_path);
                system(cmd);
            }

            if (access(out_path, F_OK) == 0) {
                printf("%s\"%s\": \"%s\"", (first ? "" : ", "), entry_id, out_path);
                first = 0;
            }
        }
    }

    pclose(pipe);
    printf("}\n");
    return 0;
}
