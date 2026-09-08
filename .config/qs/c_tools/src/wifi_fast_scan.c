#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
    printf("SAVED:\n");
    FILE *f1 = popen("nmcli -t -f NAME,TYPE connection show 2>/dev/null", "r");
    if (f1) {
        char line[512];
        while (fgets(line, sizeof(line), f1)) {
            line[strcspn(line, "\r\n")] = 0;
            char *target = ":802-11-wireless";
            char *pos = strstr(line, target);
            if (pos && strcmp(pos, target) == 0) {
                *pos = '\0';
                printf("%s\n", line);
            }
        }
        pclose(f1);
    }

    printf("SCANNED:\n");
    FILE *f2 = popen("nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE device wifi list 2>/dev/null", "r");
    if (f2) {
        char line[512];
        while (fgets(line, sizeof(line), f2)) {
            fputs(line, stdout);
        }
        pclose(f2);
    }

    return 0;
}
