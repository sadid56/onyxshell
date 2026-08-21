import time
import subprocess
import sys
import json
import os

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
            text=True
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

def main():
    last_rx, last_tx = get_net_bytes()
    last_time = time.time()
    ssid = get_ssid()
    signal = get_wifi_signal()

    try:
        print(json.dumps({"ssid": ssid, "down": "0 B/s", "up": "0 B/s", "signal": signal}), flush=True)
    except BrokenPipeError:
        sys.exit(0)

    ssid_counter = 0

    while True:
        try:
            if os.getppid() == 1:
                sys.exit(0)

            time.sleep(1.0)
            now = time.time()
            rx, tx = get_net_bytes()
            dt = now - last_time
            if dt <= 0:
                continue

            down_speed = (rx - last_rx) / dt
            up_speed = (tx - last_tx) / dt

            last_rx, last_tx = rx, tx
            last_time = now

            signal = get_wifi_signal()

            ssid_counter += 1
            if signal == -1:
                ssid = get_ssid()
                ssid_counter = 0
            elif ssid_counter >= 4 or ssid == "Disconnected":
                ssid = get_ssid()
                ssid_counter = 0

            print(json.dumps({
                "ssid": ssid,
                "down": format_speed(down_speed),
                "up": format_speed(up_speed),
                "signal": signal
            }), flush=True)
        except (KeyboardInterrupt, BrokenPipeError):
            break
        except Exception:
            time.sleep(1.0)

if __name__ == "__main__":
    main()
