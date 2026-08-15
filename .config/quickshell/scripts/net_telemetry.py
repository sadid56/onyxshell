import time
import subprocess
import sys
import json

def get_ssid():
    try:
        res = subprocess.check_output(
            "nmcli -t -f NAME,TYPE connection show --active | grep -E '802-11-wireless|ethernet' | head -n 1 | cut -d: -f1",
            shell=True, text=True
        ).strip()
        return res if res else "Disconnected"
    except Exception:
        return "Disconnected"

def get_net_bytes():
    rx = 0
    tx = 0
    try:
        with open("/proc/net/dev", "r") as f:
            lines = f.readlines()
            for line in lines:
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

last_rx, last_tx = get_net_bytes()
last_time = time.time()
ssid = get_ssid()

# Print initially
print(json.dumps({"ssid": ssid, "down": "0 B/s", "up": "0 B/s"}), flush=True)

ssid_counter = 0

while True:
    try:
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
        
        def format_speed(speed):
            if speed < 1024:
                return f"{int(speed)} B/s"
            elif speed < 1024 * 1024:
                return f"{speed / 1024:.1f} KB/s"
            else:
                return f"{speed / (1024 * 1024):.1f} MB/s"
                
        ssid_counter += 1
        if ssid_counter >= 5:
            ssid = get_ssid()
            ssid_counter = 0
            
        print(json.dumps({"ssid": ssid, "down": format_speed(down_speed), "up": format_speed(up_speed)}), flush=True)
    except KeyboardInterrupt:
        break
    except Exception:
        time.sleep(1.0)
