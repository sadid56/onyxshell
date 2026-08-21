import os
import sys
import json
import re

CACHE_FILE = "/tmp/quickshell_apps_cache.json"
MAX_CACHE_AGE = 3600  # 1 hour max, even if nothing changed

app_dirs = [
    "/usr/share/applications",
    os.path.expanduser("~/.local/share/applications")
]

icon_theme_dirs = [
    os.path.expanduser("~/.local/share/icons"),
    os.path.expanduser("~/.icons"),
    "/usr/share/icons",
    "/usr/share/pixmaps"
]

def is_cache_valid():
    if not os.path.exists(CACHE_FILE):
        return False
    try:
        import time
        cache_mtime = os.path.getmtime(CACHE_FILE)

        # Max age check
        if time.time() - cache_mtime > MAX_CACHE_AGE:
            return False

        # Check if any app directory or its .desktop files changed
        for d in app_dirs:
            if not os.path.exists(d):
                continue
            if os.path.getmtime(d) > cache_mtime:
                return False
            for f in os.listdir(d):
                if f.endswith(".desktop"):
                    fp = os.path.join(d, f)
                    if os.path.getmtime(fp) > cache_mtime:
                        return False

        # Check if icon theme root dirs changed (theme install/switch)
        for d in icon_theme_dirs:
            if os.path.exists(d) and os.path.getmtime(d) > cache_mtime:
                return False

        return True
    except Exception:
        return False

if is_cache_valid():
    try:
        with open(CACHE_FILE, "r", encoding="utf-8") as f:
            content = f.read()
            if content.strip():
                print(content)
                sys.exit(0)
    except Exception:
        pass

DEFAULT_APP_ICON = os.path.expanduser("~/.config/quickshell/assets/icons/system/default-app.svg")

def icon_score(path):
    p = path.lower()
    score = 0
    if "/apps/" in p or "/pixmaps" in p:
        score += 100
    if "/scalable/" in p:
        score += 50
    elif "/128x128/" in p or "/256x256/" in p or "/512x512/" in p:
        score += 40
    elif "/64x64/" in p or "/48x48/" in p:
        score += 30
    elif "/32x32/" in p:
        score += 20
    elif "/16x16/" in p or "/22x22/" in p or "/mimes/" in p:
        score -= 50
    if path.endswith(".svg"):
        score += 10
    return score

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
            for f in files:
                if f.endswith((".png", ".svg", ".xpm")):
                    name, _ = os.path.splitext(f)
                    full_p = os.path.join(root, f)
                    if name not in icon_cache or icon_score(full_p) > icon_score(icon_cache[name]):
                        icon_cache[name] = full_p

build_icon_cache()

def resolve_icon(name):
    if not name:
        return DEFAULT_APP_ICON
    if os.path.isabs(name) and os.path.exists(name):
        return name
    if name in icon_cache:
        return icon_cache[name]
    # Check if name has an extension
    base, _ = os.path.splitext(name)
    if base in icon_cache:
        return icon_cache[base]
    for fallback in ["application-x-executable", "system-run", "application-default-icon", "utilities-terminal"]:
        if fallback in icon_cache:
            return icon_cache[fallback]
    return DEFAULT_APP_ICON

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

for d in app_dirs:
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

                    icon_name = icon_match.group(1).strip() if icon_match else ""
                    icon_path = resolve_icon(icon_name) if icon_name else ""

                    if not icon_path or not os.path.exists(icon_path):
                        icon_path = DEFAULT_APP_ICON

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
