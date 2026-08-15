import os
import json
import re

dirs = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

icon_cache = {}

def build_icon_cache():
    icon_dirs = [
        os.path.expanduser("~/.local/share/icons"),
        os.path.expanduser("~/.icons"),
        "/usr/share/icons",
        "/usr/share/pixmaps"
    ]
    for root_dir in icon_dirs:
        if not os.path.exists(root_dir):
            continue
        for root, subdirs, files in os.walk(root_dir):
            is_apps_dir = "apps" in root or "pixmaps" in root or "mimes" in root or "mimetypes" in root or root_dir == "/usr/share/pixmaps"
            if not is_apps_dir:
                continue
            for f in files:
                if f.endswith((".png", ".svg", ".xpm")):
                    name, _ = os.path.splitext(f)
                    if name not in icon_cache:
                        icon_cache[name] = os.path.join(root, f)

# Build the cache once
build_icon_cache()

def resolve_icon(name):
    if not name:
        return ""
    if os.path.isabs(name):
        return name
    return icon_cache.get(name, "")

apps = []
seen_names = set()

for d in dirs:
    if not os.path.exists(d):
        continue
    for f in os.listdir(d):
        if not f.endswith(".desktop"):
            continue
        path = os.path.join(d, f)
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as file:
                content = file.read()
                
                type_match = re.search(r"^Type=(.+)$", content, re.MULTILINE)
                if type_match and type_match.group(1).strip() != "Application":
                    continue
                
                name_match = re.search(r"^Name=(.+)$", content, re.MULTILINE)
                exec_match = re.search(r"^Exec=(.+)$", content, re.MULTILINE)
                icon_match = re.search(r"^Icon=(.+)$", content, re.MULTILINE)
                comment_match = re.search(r"^Comment=(.+)$", content, re.MULTILINE)
                nodisplay_match = re.search(r"^NoDisplay=(true|1)$", content, re.MULTILINE | re.IGNORECASE)
                
                if name_match and exec_match and not nodisplay_match:
                    name = name_match.group(1).strip()
                    exec_cmd = exec_match.group(1).strip()
                    exec_cmd = re.sub(r"%[fFuuNodDiks]", "", exec_cmd).strip()
                    
                    if name in seen_names:
                        continue
                    seen_names.add(name)
                    
                    icon_name = icon_match.group(1).strip() if icon_match else "application-x-executable"
                    icon_path = resolve_icon(icon_name)
                    
                    if not icon_path:
                        icon_path = resolve_icon("application-x-executable")
                    if not icon_path:
                        icon_path = resolve_icon("system-run")
                    
                    comment = comment_match.group(1).strip() if comment_match else ""
                    
                    apps.append({
                        "name": name,
                        "exec": exec_cmd,
                        "icon": icon_path,
                        "comment": comment
                    })
        except Exception:
            pass

apps.sort(key=lambda x: x["name"].lower())
print(json.dumps(apps))
