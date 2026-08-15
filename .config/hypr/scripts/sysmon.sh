#!/bin/bash

# Hide cursor and restore on exit
trap "tput cnorm; exit" INT TERM EXIT
tput civis

CORES=$(nproc)

while true; do
    # Clear screen and move cursor to top-left (avoiding scrollback pollution)
    printf "\033[H\033[2J"

    # --- 1. System Memory & Swap Stats ---
    free -m | awk '
    BEGIN {
        C_CYA = "\033[1;36m"; C_GRE = "\033[1;32m"; C_YEL = "\033[1;33m";
        C_RED = "\033[1;31m"; C_MAG = "\033[1;35m"; C_RES = "\033[0m";
    }
    /^Mem:/ {
        printf " %sRAM%s   Total: %s%5.1f GB%s │ Used: %s%5.1f GB%s │ Free: %s%5.1f GB%s │ Cache: %s%5.1f GB%s\n",
               C_CYA, C_RES,  C_GRE, $2/1024, C_RES,  C_RED, $3/1024, C_RES,  C_GRE, $4/1024, C_RES,  C_YEL, $6/1024, C_RES
    }
    /^Swap:/ {
        printf " %sSWAP%s  Total: %s%5.1f GB%s │ Used: %s%5.1f GB%s │ Free: %s%5.1f GB%s\n",
               C_MAG, C_RES,  C_GRE, $2/1024, C_RES,  C_RED, $3/1024, C_RES,  C_GRE, $4/1024, C_RES
    }
    '

    # Divider
    echo -e "\033[0;34m ───────────────────────────────────────────────────────────────────────────────\033[0m"

    # Header
    echo -e "   \033[1;36mCPU% \033[1;32m          MEM% \033[1;33m            RAM USED \033[1;35m             APPLICATION\033[0m"
    echo -e "  \033[0;36m──────\033[0;32m        ───────\033[0;33m          ────────────\033[0;35m            ───────────────\033[0m"

    # Grab and process stats using a single optimized awk call
    ps -eo pcpu,pmem,rss,comm --no-headers | awk -v cores="$CORES" '
    {
        app_name = $4;
        for (i=5; i<=NF; i++) app_name = app_name " " $i;
        
        cpu[app_name] += $1/cores;
        mem[app_name] += $2;
        ram[app_name] += $3/1024;
    }
    END {
        # Sort by values (RAM usage) descending in gawk
        PROCINFO["sorted_in"] = "@val_num_desc";
        
        count = 0;
        for (app in ram) {
            count++;
            if (count > 15) break;

            cpu_val = cpu[app];
            mem_val = mem[app];
            ram_val = ram[app];

            C_CYAN   = "\033[1;36m";
            C_GREEN  = "\033[1;32m";
            C_YELLOW = "\033[1;33m";
            C_RED    = "\033[1;31m";
            C_MAG    = "\033[1;35m";
            C_RESET  = "\033[0m";

            if (ram_val >= 1024) {
                ram_str = sprintf("%.2f GB", ram_val/1024);
                ram_col = C_RED;
            } else {
                ram_str = sprintf("%.0f MB", ram_val);
                ram_col = C_YELLOW;
            }

            cpu_col = (cpu_val > 15.0) ? C_RED : C_CYAN;

            printf "  %s%5.1f%%%s        %s%5.1f%%%s        %s%10s%s             %s%s%s\n",
                cpu_col, cpu_val, C_RESET,
                C_GREEN, mem_val, C_RESET,
                ram_col, ram_str, C_RESET,
                C_MAG, app, C_RESET;
        }
    }'

    sleep 1
done
