CC = gcc
CFLAGS = -O3 -march=native -Wall -Wextra -s
SRC_DIR = src
BIN_DIR = bin

TARGETS = $(BIN_DIR)/sys_telemetry $(BIN_DIR)/sys_resources $(BIN_DIR)/decode_clip $(BIN_DIR)/toggle_float

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

clean:
	rm -rf $(BIN_DIR)/*

.PHONY: all clean
