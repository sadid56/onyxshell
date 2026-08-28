#!/usr/bin/env python3

import os
import sys
import json
import re

app_dirs = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

icon_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    os.path.expanduser("~/.icons"),
    "/usr/share/icons",
    "/usr/share/pixmaps"
]

def icon_score(path):
    p = path.lower()
    score = 0
    if "symbolic" in p:
        score -= 200
    if "/apps/" in p or "/applications/" in p or "/pixmaps" in p:
        score += 100
    if "/scalable/" in p:
        score += 60
    elif "/256x256/" in p or "/128x128/" in p:
        score += 50
    elif "/64x64/" in p or "/48x48/" in p:
        score += 40
    if path.endswith(".svg"):
        score += 15
    elif path.endswith(".png"):
        score += 10
    return score

icon_cache = {}
for root_dir in icon_dirs:
    if not os.path.exists(root_dir):
        continue
    for root, subdirs, files in os.walk(root_dir):
        for f in files:
            if f.endswith((".png", ".svg", ".xpm")):
                name, _ = os.path.splitext(f)
                full_p = os.path.join(root, f)
                if name not in icon_cache or icon_score(full_p) > icon_score(icon_cache[name]):
                    icon_cache[name] = full_p

def resolve_icon(name):
    if not name:
        return ""
    if os.path.isabs(name) and os.path.exists(name):
        return name
    if name in icon_cache:
        return icon_cache[name]
    base, _ = os.path.splitext(name)
    if base in icon_cache:
        return icon_cache[base]
    return ""

def get_notification_apps():
    apps = []
    seen = set()

    apps.append({
        "id": "quickshell",
        "name": "System & Desktop Shell",
        "icon": "system/app-window.svg",
        "comment": "Desktop notifications, battery alerts, and system popups",
        "isSystem": True,
        "aliases": ["quickshell", "system", "hyprland", "desktop", "notify-send"]
    })
    seen.add("quickshell")

    blacklist_stems = {"bssh", "bvnc", "qv4l2", "qvidcap"}

    for d in app_dirs:
        if not os.path.exists(d):
            continue
        for f in sorted(os.listdir(d)):
            if not f.endswith(".desktop"):
                continue
            stem = f[:-8].lower()
            if stem in blacklist_stems:
                continue

            p = os.path.join(d, f)
            try:
                with open(p, "r", encoding="utf-8", errors="ignore") as file:
                    content = file.read()
                    if "NoDisplay=true" in content:
                        continue
                    type_m = re.search(r"^Type=(.+)$", content, re.MULTILINE)
                    if type_m and type_m.group(1).strip() != "Application":
                        continue

                    name_m = re.search(r"^Name=(.+)$", content, re.MULTILINE)
                    exec_m = re.search(r"^Exec=(.+)$", content, re.MULTILINE)
                    icon_m = re.search(r"^Icon=(.+)$", content, re.MULTILINE)
                    comment_m = re.search(r"^Comment=(.+)$", content, re.MULTILINE)

                    if name_m and exec_m:
                        name = name_m.group(1).strip()
                        if name.lower() in seen:
                            continue
                        seen.add(name.lower())

                        exec_cmd = exec_m.group(1).strip().split()[0]
                        exec_base = os.path.basename(exec_cmd)
                        icon_name = icon_m.group(1).strip() if icon_m else ""
                        icon_path = resolve_icon(icon_name)
                        comment = comment_m.group(1).strip() if comment_m else ""

                        aliases = list(set([
                            name.lower(),
                            stem,
                            exec_base.lower(),
                            name.lower().replace(" ", "-"),
                            name.lower().replace(" ", "")
                        ]))

                        apps.append({
                            "id": stem,
                            "name": name,
                            "icon": icon_path if icon_path else "system/default-app.svg",
                            "comment": comment,
                            "isSystem": False,
                            "aliases": aliases
                        })
            except Exception:
                pass

    def app_priority(a):
        if a.get("isSystem"):
            return 0
        n = a["name"].lower()
        if any(x in n for x in ["brave", "chrome", "firefox", "browser", "discord", "telegram", "slack", "spotify", "music", "localsend", "mail", "thunderbird"]):
            return 1
        if any(x in n for x in ["code", "ide", "editor", "vlc", "player", "steam", "nautilus", "files", "terminal", "kitty"]):
            return 2
        return 3

    apps.sort(key=lambda x: (app_priority(x), x["name"].lower()))
    return apps

if __name__ == "__main__":
    print(json.dumps(get_notification_apps()))
