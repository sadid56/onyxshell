#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define PREVIEW_DIR "/tmp/cliphist_previews"

int main(void) {
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
