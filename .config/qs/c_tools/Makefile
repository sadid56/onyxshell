CC = gcc
CFLAGS = -O3 -march=native -Wall -Wextra -s
SRC_DIR = src
BIN_DIR = bin

TARGETS = $(BIN_DIR)/sys_telemetry $(BIN_DIR)/sys_resources $(BIN_DIR)/decode_clip $(BIN_DIR)/toggle_float $(BIN_DIR)/hypr_dropdown $(BIN_DIR)/quick_stats $(BIN_DIR)/alt_tab_clients $(BIN_DIR)/wifi_fast_scan $(BIN_DIR)/fast_wallpapers

all: $(BIN_DIR) $(TARGETS)

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

$(BIN_DIR)/sys_telemetry: $(SRC_DIR)/sys_telemetry.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/sys_resources: $(SRC_DIR)/sys_resources.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/decode_clip: $(SRC_DIR)/decode_clip.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/toggle_float: $(SRC_DIR)/toggle_float.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/hypr_dropdown: $(SRC_DIR)/hypr_dropdown.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/quick_stats: $(SRC_DIR)/quick_stats.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/alt_tab_clients: $(SRC_DIR)/alt_tab_clients.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/wifi_fast_scan: $(SRC_DIR)/wifi_fast_scan.c
	$(CC) $(CFLAGS) $< -o $@

$(BIN_DIR)/fast_wallpapers: $(SRC_DIR)/fast_wallpapers.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -rf $(BIN_DIR)/*

.PHONY: all clean
