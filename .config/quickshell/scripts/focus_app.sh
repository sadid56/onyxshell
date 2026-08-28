#!/usr/bin/env python3
import sys
import json
import subprocess
import re

app_name = sys.argv[1] if len(sys.argv) > 1 else ""
summary = sys.argv[2] if len(sys.argv) > 2 else ""
body = sys.argv[3] if len(sys.argv) > 3 else ""

combined = f"{app_name} {summary} {body}".strip()
combined_lower = combined.lower()

def run_cmd(cmd):
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode().strip()
    except Exception:
        return ""

def focus_address(addr):
    if addr:
        lua_cmd = f"hl.dispatch(hl.dsp.focus({{ window = 'address:{addr}' }}))"
        subprocess.run(["hyprctl", "eval", lua_cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    return False

clients_raw = run_cmd(["hyprctl", "clients", "-j"])
clients = []
if clients_raw:
    try:
        clients = json.loads(clients_raw)
    except Exception:
        clients = []

if not clients:
    sys.exit(0)

best_client = None
best_score = 0

notif_words = [w for w in re.findall(r'[\w]+', combined_lower) if len(w) >= 2]
summary_lower = summary.strip().lower()

for c in clients:
    score = 0
    title = (c.get("title") or "").lower()
    cls = (c.get("class") or "").lower()
    init_title = (c.get("initialTitle") or "").lower()

    if summary_lower and len(summary_lower) > 2 and summary_lower in title:
        score += 200

    if any(k in combined_lower for k in ["facebook", "messenger", "fb"]):
        if "facebook" in title or "facebook" in cls:
            score += 150
        if "messenger" in title or "messenger" in cls:
            score += 150

    if "whatsapp" in combined_lower:
        if "whatsapp" in title or "whatsapp" in cls:
            score += 150

    if "telegram" in combined_lower and "telegram" in cls:
        score += 120
    if ("discord" in combined_lower or "vesktop" in combined_lower) and ("discord" in cls or "vesktop" in cls):
        score += 120
    if "spotify" in combined_lower and "spotify" in cls:
        score += 120
    if ("antigravity" in combined_lower or "code" in combined_lower) and ("antigravity" in cls or "code" in cls):
        score += 120

    if any(b in combined_lower for b in ["brave", "chrome", "firefox", "chromium"]):
        if any(b in cls for b in ["brave", "chrome", "firefox", "chromium"]):
            score += 60

    for w in notif_words:
        if w in title:
            score += 30
        if w in cls:
            score += 20

    if "facebook" in title and any(b in cls for b in ["brave", "chrome", "firefox"]):
        score += 40
    if "whatsapp" in title and any(b in cls for b in ["brave", "chrome", "firefox"]):
        score += 40

    if score > best_score:
        best_score = score
        best_client = c

if best_client and best_score > 0:
    addr = best_client.get("address")
    if addr and focus_address(addr):
        sys.exit(0)

url_match = re.search(r'(https?://[^\s]+|www\.[^\s]+)', combined)
if url_match:
    u = url_match.group(1)
    if not u.startswith("http://") and not u.startswith("https://"):
        u = "https://" + u
    subprocess.Popen(["xdg-open", u], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
elif any(k in combined_lower for k in ["facebook", "messenger"]):
    subprocess.Popen(["xdg-open", "https://www.facebook.com"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
elif app_name:
    try:
        subprocess.Popen(["gtk-launch", app_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        subprocess.Popen(["xdg-open", app_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
