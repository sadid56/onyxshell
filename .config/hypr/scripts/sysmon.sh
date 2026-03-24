#!/bin/bash

# Clear the screen for a clean refresh
clear

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

# Wider subtle divider line
echo -e "\033[0;34m ───────────────────────────────────────────────────────────────────────────────\033[0m"

# --- 2. Print a wider, colorful header ---
echo -e "   \033[1;36mCPU% \033[1;32m          MEM% \033[1;33m            RAM USED \033[1;35m             APPLICATION\033[0m"
echo -e "  \033[0;36m──────\033[0;32m        ───────\033[0;33m          ────────────\033[0;35m            ───────────────\033[0m"

# --- 3. Process math & formatting ---
# Grab the number of CPU cores
CORES=$(nproc)

ps -eo pcpu,pmem,rss,comm --no-headers |
  awk -v cores="$CORES" '{
    # Divide the CPU usage by the number of cores to get true system %
    cpu[$4]+=$1/cores;
    mem[$4]+=$2;
    ram[$4]+=$3/1024;
}
END {
    for (app in ram) {
        printf "%.1f %.1f %.2f %s\n", cpu[app], mem[app], ram[app], app
    }
}' |
  sort -rn -k3 |
  head -n 15 |
  awk '{
    cpu_val = $1;
    mem_val = $2;
    ram_val = $3;
    
    app_name = $4;
    for (i=5; i<=NF; i++) app_name = app_name " " $i;

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

    # Smart CPU Formatting: Turn RED if over 15% of TOTAL system CPU
    cpu_col = (cpu_val > 15.0) ? C_RED : C_CYAN;

    # Spaced out perfectly to match the top row width
    printf "  %s%5.1f%%%s        %s%5.1f%%%s        %s%10s%s             %s%s%s\n",
        cpu_col, cpu_val, C_RESET,
        C_GREEN, mem_val, C_RESET,
        ram_col, ram_str, C_RESET,
        C_MAG, app_name, C_RESET;
}'
