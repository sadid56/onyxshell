import os
import sys
import json
import re

CACHE_FILE = "/tmp/quickshell_apps_cache.json"

dirs = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

if os.path.exists(CACHE_FILE):
    try:
        cache_mtime = os.path.getmtime(CACHE_FILE)
        valid = True
        for d in dirs:
            if os.path.exists(d) and os.path.getmtime(d) > cache_mtime:
                valid = False
                break
        if valid:
            with open(CACHE_FILE, "r", encoding="utf-8") as f:
                content = f.read()
                if content.strip():
                    print(content)
                    sys.exit(0)
    except Exception:
        pass

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

build_icon_cache()

def resolve_icon(name):
    if not name:
        return ""
    if os.path.isabs(name):
        return name
    return icon_cache.get(name, "")

def parse_categories(cat_str):
    if not cat_str:
        return ["Utilities"]
    
    raw = [c.strip() for c in cat_str.split(";") if c.strip()]
    cats = set()
    
    for c in raw:
        cl = c.lower()
        if any(x in cl for x in ["develop", "ide", "debugger", "building", "programming", "code"]):
            cats.add("Development")
        elif any(x in cl for x in ["network", "web", "browser", "email", "chat", "irc", "feed", "telephony", "filetransfer"]):
            cats.add("Internet")
        elif any(x in cl for x in ["audiovideo", "audio", "video", "player", "recorder", "music", "tv", "mixer", "sound"]):
            cats.add("Multimedia")
        elif any(x in cl for x in ["graphics", "2dgraphics", "vector", "raster", "photo", "image", "viewer", "paint", "draw"]):
            cats.add("Graphics")
        elif any(x in cl for x in ["office", "word", "spreadsheet", "presentation", "publish", "finance", "calendar", "contact"]):
            cats.add("Office")
        elif any(x in cl for x in ["game", "arcade", "puzzle", "action", "simulator"]):
            cats.add("Games")
        elif any(x in cl for x in ["setting", "preferences", "control", "hardware", "package"]):
            cats.add("Settings")
        elif any(x in cl for x in ["system", "emulator", "terminal", "filemanager", "monitor", "security", "core"]):
            cats.add("System")
        elif any(x in cl for x in ["utility", "accessories", "archive", "compression", "calc", "clock", "texteditor", "editor"]):
            cats.add("Utilities")
            
    if not cats:
        cats.add("Utilities")
    return sorted(list(cats))

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
                cat_match = re.search(r"^Categories=(.+)$", content, re.MULTILINE)
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

                    if not icon_path or not os.path.exists(icon_path):
                        icon_path = resolve_icon("application-x-executable")
                    if not icon_path or not os.path.exists(icon_path):
                        icon_path = resolve_icon("system-run")
                    if not icon_path or not os.path.exists(icon_path):
                        icon_path = ""

                    comment = comment_match.group(1).strip() if comment_match else ""
                    categories = parse_categories(cat_match.group(1).strip() if cat_match else "")

                    apps.append({
                        "name": name,
                        "exec": exec_cmd,
                        "icon": icon_path,
                        "comment": comment,
                        "categories": categories
                    })
        except Exception:
            pass

apps.sort(key=lambda x: x["name"].lower())
output_json = json.dumps(apps)
try:
    with open(CACHE_FILE, "w", encoding="utf-8") as f:
        f.write(output_json)
except Exception:
    pass
print(output_json)
