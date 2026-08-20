import os
import re
import json

def get_readable_action(raw_keys, raw_action):
    act = raw_action.lower()

    if "terminal" in act or "kitty" in act:
        if "dropdown" in act:
            return "Toggle Dropdown Terminal", "Applications", ""
        if "sysmon" in act or "btop" in act or "htop" in act:
            return "Open System Monitor", "System", "󰾆"
        return "Open Terminal", "Applications", ""

    if "filemanager" in act or "nautilus" in act or "yazi" in act or "thunar" in act:
        return "Open File Manager", "Applications", ""

    if "togglelauncher" in act or "rofi" in act or "wofi" in act:
        return "Open App Launcher", "Applications", "󰍉"

    if "browser" in act or "brave" in act or "chrome" in act or "firefox" in act:
        return "Open Web Browser", "Applications", ""

    if "hyprlock" in act:
        return "Lock Screen", "System", ""

    if "reload.sh" in act or "reload" in act:
        return "Reload Hyprland & Shell", "System", ""

    if "togglebar" in act:
        return "Toggle Status Bar", "System", "󱔐"

    if "togglekeybinds" in act:
        return "Show Keybindings Helper", "System", ""

    if "toggleclipboard" in act:
        return "Open Clipboard History", "System", "󰆏"

    if "toggleemoji" in act:
        return "Open Emoji Picker", "System", "󰞅"

    if "cliphist wipe" in act:
        return "Clear Clipboard History", "System", "󰃢"

    if "togglenotifications" in act:
        return "Open Notification Center", "System", "󰂚"

    if "togglewallpaperselector" in act:
        return "Open Wallpaper Selector", "System", "󰸉"

    if "togglealttab" in act or "closealttab" in act:
        return "Switch Window (Alt-Tab)", "Window", "󰓩"

    if "shutdown.sh" in act:
        return "Open Power Menu", "System", ""

    if "screenshot.sh" in act or "hyprshot" in act:
        if "window" in act:
            return "Screenshot Active Window", "Screenshot", ""
        if "region" in act:
            return "Screenshot Selected Region", "Screenshot", ""
        if "output" in act:
            return "Screenshot Full Display", "Screenshot", ""
        return "Take Screenshot", "Screenshot", ""

    if "window.close" in act or "close" in act:
        return "Close Active Window", "Window", "󰅖"

    if "toggle_float.py" in act or "window.float" in act or "float" in act:
        if "all" in act or "shift" in raw_keys.lower():
            return "Toggle Workspace Floating (All)", "Window", "󰉈"
        return "Toggle Window Floating", "Window", "󰉈"

    if "togglesplit" in act:
        return "Toggle Split Orientation", "Window", "󰤉"

    if "fullscreen" in act:
        return "Toggle Fullscreen", "Window", "󰊓"

    if "group.next" in act:
        return "Cycle Window in Group", "Window", "󰓩"

    if "group.toggle" in act:
        return "Toggle Window Grouping", "Window", "󰓩"

    if "workspace.toggle_special" in act:
        return "Toggle Scratchpad (Magic)", "Workspaces", "󰌨"

    if "special:magic" in act:
        return "Move Window to Scratchpad", "Workspaces", "󰌨"

    if "+0" in act and "workspace" in act:
        return "Bring Window from Scratchpad", "Workspaces", "󰌨"

    if "focus" in act and "direction" in act:
        if '"l"' in act or "'l'" in act: return "Focus Window Left", "Navigation", ""
        if '"r"' in act or "'r'" in act: return "Focus Window Right", "Navigation", ""
        if '"u"' in act or "'u'" in act: return "Focus Window Up", "Navigation", ""
        if '"d"' in act or "'d'" in act: return "Focus Window Down", "Navigation", ""
        return "Focus Window", "Navigation", "󰁔"

    if "window.move" in act and "direction" in act:
        if '"l"' in act or "'l'" in act: return "Move Window Left", "Window", ""
        if '"r"' in act or "'r'" in act: return "Move Window Right", "Window", ""
        if '"u"' in act or "'u'" in act: return "Move Window Up", "Window", ""
        if '"d"' in act or "'d'" in act: return "Move Window Down", "Window", ""
        return "Move Window", "Window", "󰆂"

    if "window.resize" in act:
        return "Resize Active Window", "Window", "󰩨"

    if "wpctl set-volume" in act:
        if "+" in act: return "Volume Up", "Media", ""
        if "-" in act: return "Volume Down", "Media", ""
        return "Adjust Volume", "Media", ""

    if "set-mute" in act:
        if "source" in act: return "Toggle Mic Mute", "Media", "󰍭"
        return "Toggle Audio Mute", "Media", "󰝟"

    if "brightnessctl" in act:
        if "+" in act: return "Brightness Up", "System", "󰃠"
        return "Brightness Down", "System", "󰃟"

    if "playerctl" in act:
        if "next" in act: return "Next Audio Track", "Media", "󰒭"
        if "prev" in act: return "Previous Audio Track", "Media", "󰒮"
        return "Play / Pause Audio", "Media", "󰐊"

    if "focus workspace" in raw_action.lower():
        num = raw_action.split()[-1]
        return f"Switch to Workspace {num}", "Workspaces", "󰎤"
    if "move window to workspace" in raw_action.lower():
        num = raw_action.split()[-1]
        return f"Move Window to Workspace {num}", "Workspaces", "󰎤"

    clean_act = raw_action.replace("hl.dsp.", "").replace("exec_cmd", "").replace("(", "").replace(")", "").strip()
    return clean_act if clean_act else "Perform Action", "General", ""

def parse_keybinds():
    filepath = os.path.expanduser("~/.config/hypr/lua/keybinds.lua")
    if not os.path.exists(filepath):
        return []

    keybinds = []

    variables = {
        "mainMod": "SUPER",
        "secondMod": "ALT",
        "terminal": "kitty",
        "fileManager": "nautilus",
        "menu": "Launcher",
        "browser": "brave-origin"
    }

    with open(filepath, 'r') as f:
        content = f.read()

    bind_pattern = re.compile(r'hl\.bind\(\s*([\s\S]*?)\s*,\s*([\s\S]*?)\s*(?:,\s*\{[\s\S]*?\})?\s*\)', re.MULTILINE)

    for match in bind_pattern.finditer(content):
        key_expr = match.group(1).strip()
        action_expr = match.group(2).strip()

        if "for " in key_expr or (".. i" in key_expr and "workspace" in action_expr):
            continue

        keys = key_expr
        for var, val in variables.items():
            keys = re.sub(r'\b' + var + r'\b', val, keys)

        keys = keys.replace('..', '').replace('"', '').replace("'", '').replace('\n', ' ').strip()
        keys = re.sub(r'\s*\+\s*', ' + ', keys)
        keys = re.sub(r'\s+', ' ', keys)

        action = action_expr.replace('\n', ' ')
        if action.startswith('hl.dsp.exec_cmd('):
            action = action[16:-1]
        elif action.startswith('hl.dsp.'):
            action = action[7:]

        for var, val in variables.items():
            action = re.sub(r'\b' + var + r'\b', val, action)

        action = action.replace('"', '').replace("'", '').strip()

        desc, category, icon = get_readable_action(keys, action)

        keybinds.append({
            "keys": keys,
            "action": desc,
            "category": category,
            "icon": icon,
            "raw": action
        })

    for i in range(1, 10):
        keybinds.append({
            "keys": f"SUPER + {i}",
            "action": f"Switch to Workspace {i}",
            "category": "Workspaces",
            "icon": "󰎤",
            "raw": f"focus workspace {i}"
        })
        keybinds.append({
            "keys": f"SUPER + SHIFT + {i}",
            "action": f"Move Window to Workspace {i}",
            "category": "Workspaces",
            "icon": "󰎤",
            "raw": f"move window to workspace {i}"
        })

    keybinds.append({
        "keys": "SUPER + 0",
        "action": "Switch to Workspace 10",
        "category": "Workspaces",
        "icon": "󰎤",
        "raw": "focus workspace 10"
    })
    keybinds.append({
        "keys": "SUPER + SHIFT + 0",
        "action": "Move Window to Workspace 10",
        "category": "Workspaces",
        "icon": "󰎤",
        "raw": "move window to workspace 10"
    })

    return keybinds

if __name__ == "__main__":
    print(json.dumps(parse_keybinds()))
