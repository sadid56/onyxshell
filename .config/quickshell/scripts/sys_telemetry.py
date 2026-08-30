#!/usr/bin/env python3

import time
import subprocess
import sys
import json
import os
import signal

def handle_exit(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_exit)
signal.signal(signal.SIGINT, handle_exit)
if hasattr(signal, 'SIGHUP'):
    signal.signal(signal.SIGHUP, handle_exit)

def get_wifi_signal():
    try:
        with open("/proc/net/wireless", "r") as f:
            for line in f:
                if ":" in line:
                    parts = line.split()
                    val = float(parts[2].replace('.', ''))
                    return int(min(100, max(0, (val / 70.0) * 100)))
    except Exception:
        pass
    return -1

def get_net_bytes():
    rx = 0
    tx = 0
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if ":" in line:
                    parts = line.split(":")
                    if parts[0].strip() == "lo":
                        continue
                    dev_parts = parts[1].split()
                    rx += int(dev_parts[0])
                    tx += int(dev_parts[8])
    except Exception:
        pass
    return rx, tx

def get_ssid():
    try:
        res = subprocess.check_output(
            ["nmcli", "-t", "-f", "NAME,TYPE", "connection", "show", "--active"],
            text=True,
            timeout=1.0
        )
        for line in res.splitlines():
            parts = line.split(":")
            if len(parts) >= 2 and parts[1] in ("802-11-wireless", "802-3-ethernet", "ethernet"):
                return parts[0].strip()
        return "Disconnected"
    except Exception:
        return "Disconnected"

def format_speed(speed):
    if speed < 1024:
        return f"{int(speed)} B/s"
    elif speed < 1024 * 1024:
        return f"{speed / 1024:.1f} KB/s"
    else:
        return f"{speed / (1024 * 1024):.1f} MB/s"

def get_cpu_times():
    try:
        with open("/proc/stat", "r") as f:
            for line in f:
                if line.startswith("cpu "):
                    parts = [int(x) for x in line.split()[1:]]
                    idle = parts[3] + (parts[4] if len(parts) > 4 else 0)
                    total = sum(parts)
                    return total, idle
    except Exception:
        pass
    return 0, 0

def get_memory_info():
    total = 0
    available = 0
    swap_total = 0
    swap_free = 0
    try:
        with open("/proc/meminfo", "r") as f:
            for line in f:
                if line.startswith("MemTotal:"):
                    total = int(line.split()[1])
                elif line.startswith("MemAvailable:"):
                    available = int(line.split()[1])
                elif line.startswith("SwapTotal:"):
                    swap_total = int(line.split()[1])
                elif line.startswith("SwapFree:"):
                    swap_free = int(line.split()[1])
    except Exception:
        pass

    mem_usage = round(((total - available) / total) * 100, 1) if total > 0 else 0.0
    swap_usage = round(((swap_total - swap_free) / swap_total) * 100, 1) if swap_total > 0 else 0.0
    return mem_usage, swap_usage

def get_battery_info():
    capacity = 100
    is_charging = False
    bat_path = "/sys/class/power_supply/BAT0"
    if not os.path.exists(bat_path):

        bat_path = "/sys/class/power_supply/BAT1"

    if os.path.exists(bat_path):
        try:
            with open(f"{bat_path}/capacity", "r") as f:
                capacity = int(f.read().strip())
        except Exception:
            pass
        try:
            with open(f"{bat_path}/status", "r") as f:
                status = f.read().strip()
                is_charging = status in ("Charging", "Full")
        except Exception:
            pass
    return capacity, is_charging

def main():
    last_rx, last_tx = get_net_bytes()
    last_time = time.time()
    last_cpu_total, last_cpu_idle = get_cpu_times()

    cached_ssid = "Disconnected"
    ssid_timer = 0

    while True:
        try:
            time.sleep(1.5)
            curr_time = time.time()
            dt = max(0.1, curr_time - last_time)

            curr_rx, curr_tx = get_net_bytes()
            rx_speed = max(0, (curr_rx - last_rx) / dt)
            tx_speed = max(0, (curr_tx - last_tx) / dt)

            if ssid_timer % 3 == 0:
                cached_ssid = get_ssid()
            ssid_timer += 1

            wifi_signal = get_wifi_signal()

            curr_cpu_total, curr_cpu_idle = get_cpu_times()
            diff_total = curr_cpu_total - last_cpu_total
            diff_idle = curr_cpu_idle - last_cpu_idle
            cpu_usage = 0.0
            if diff_total > 0:
                cpu_usage = round(((diff_total - diff_idle) / diff_total) * 100, 1)

            mem_usage, swap_usage = get_memory_info()

            battery_cap, battery_charging = get_battery_info()

            payload = {
                "cpu": cpu_usage,
                "memory": mem_usage,
                "swap": swap_usage,
                "battery": {
                    "percentage": battery_cap,
                    "charging": battery_charging
                },
                "network": {
                    "ssid": cached_ssid,
                    "down": format_speed(rx_speed),
                    "up": format_speed(tx_speed),
                    "signal": wifi_signal
                }
            }
            print(json.dumps(payload), flush=True)

            last_rx, last_tx = curr_rx, curr_tx
            last_time = curr_time
            last_cpu_total, last_cpu_idle = curr_cpu_total, curr_cpu_idle

        except Exception as e:
            time.sleep(1.5)

if __name__ == "__main__":
    main()
