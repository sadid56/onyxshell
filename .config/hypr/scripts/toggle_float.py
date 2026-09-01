#!/usr/bin/env python3
import sys
import os
import json
import subprocess

CACHE_FILE = os.path.expanduser("~/.cache/hypr_float_geometry.json")

def load_cache():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def save_cache(cache):
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f)
    except Exception:
        pass

def run_eval(lua_code):
    subprocess.run(["hyprctl", "eval", lua_code], capture_output=True, timeout=1)

def get_active_window():
    try:
        raw = subprocess.check_output(["hyprctl", "activewindow", "-j"], timeout=1)
        return json.loads(raw)
    except Exception:
        return {}

def get_clients():
    try:
        raw = subprocess.check_output(["hyprctl", "clients", "-j"], timeout=1)
        return json.loads(raw)
    except Exception:
        return []

def get_active_workspace_id():
    try:
        raw = subprocess.check_output(["hyprctl", "activeworkspace", "-j"], timeout=1)
        return json.loads(raw).get("id", 1)
    except Exception:
        return 1

def get_monitors():
    try:
        raw = subprocess.check_output(["hyprctl", "monitors", "-j"], timeout=1)
        return json.loads(raw)
    except Exception:
        return []

def get_monitor_bounds(mon_id=None):
    monitors = get_monitors()
    for m in monitors:
        if (mon_id is not None and m.get("id") == mon_id) or (mon_id is None and m.get("focused")):
            return (
                m.get("x", 0),
                m.get("y", 0),
                m.get("width", 1920),
                m.get("height", 1080)
            )
    return (0, 0, 1920, 1080)

def toggle_single():
    win = get_active_window()
    if not win or not win.get("address"):
        return

    addr = win.get("address")
    w_class = win.get("class", "default")
    w_title = win.get("title", "")
    is_floating = win.get("floating", False)
    cache = load_cache()

    mon_x, mon_y, mon_w, mon_h = get_monitor_bounds(win.get("monitor"))

    if is_floating:
        cur_size = win.get("size", [1200, 750])
        cur_at = win.get("at", [100, 100])
        cache[addr] = {"size": cur_size, "at": cur_at}
        cache[w_class] = {"size": cur_size, "at": cur_at}
        cache[f"{w_class}:{w_title}"] = {"size": cur_size, "at": cur_at}
        save_cache(cache)

        cmd = f'hl.dispatch(hl.dsp.window.float({{ window = "address:{addr}", action = "off" }}))'
        run_eval(cmd)
    else:
        lua_cmds = []
        grouped = win.get("grouped", [])
        if grouped and len(grouped) > 1:
            lua_cmds.append(f'hl.dispatch(hl.dsp.group.toggle())')

        saved = cache.get(addr) or cache.get(w_class) or cache.get(f"{w_class}:{w_title}")
        lua_cmds.append(f'hl.dispatch(hl.dsp.window.float({{ window = "address:{addr}", action = "on" }}))')

        if saved and "size" in saved and "at" in saved:
            w, h = saved["size"]
            x, y = saved["at"]
            w = max(450, min(w, mon_w - 40))
            h = max(350, min(h, mon_h - 70))
            x = max(mon_x + 20, min(x, mon_x + mon_w - w - 20))
            y = max(mon_y + 45, min(y, mon_y + mon_h - h - 20))
            lua_cmds.append(f'hl.dispatch(hl.dsp.window.resize({{ window = "address:{addr}", x = {int(w)}, y = {int(h)}, relative = false }}))')
            lua_cmds.append(f'hl.dispatch(hl.dsp.window.move({{ window = "address:{addr}", x = {int(x)}, y = {int(y)}, relative = false }}))')
        else:
            target_w = max(750, min(1350, int(mon_w * 0.68)))
            target_h = max(500, min(850, int(mon_h * 0.68)))
            lua_cmds.append(f'hl.dispatch(hl.dsp.window.resize({{ window = "address:{addr}", x = {target_w}, y = {target_h}, relative = false }}))')
            lua_cmds.append(f'hl.dispatch(hl.dsp.window.center({{ window = "address:{addr}" }}))')

        lua_cmds.append(f'hl.dispatch(hl.dsp.focus({{ window = "address:{addr}" }}))')
        run_eval("\n".join(lua_cmds))

def toggle_all():
    cur_ws = get_active_workspace_id()
    clients = get_clients()
    ws_clients = [c for c in clients if c.get("workspace", {}).get("id") == cur_ws and not c.get("hidden")]

    cache = load_cache()
    floating_workspaces = cache.get("floating_workspaces", [])

    is_ws_floating = str(cur_ws) in floating_workspaces
    any_tiled = any(not c.get("floating", False) for c in ws_clients) if ws_clients else not is_ws_floating

    mon_x, mon_y, mon_w, mon_h = get_monitor_bounds()
    lua_commands = []

    if any_tiled:
        # Ungroup any grouped windows first so they become independent floating windows
        seen_groups = set()
        for c in ws_clients:
            grouped = c.get("grouped", [])
            if grouped and len(grouped) > 1:
                group_key = tuple(sorted(grouped))
                if group_key not in seen_groups:
                    seen_groups.add(group_key)
                    addr = c.get("address")
                    lua_commands.append(f'hl.dispatch(hl.dsp.focus({{ window = "address:{addr}" }}))')
                    lua_commands.append(f'hl.dispatch(hl.dsp.group.toggle())')

        if str(cur_ws) not in floating_workspaces:
            floating_workspaces.append(str(cur_ws))
        cache["floating_workspaces"] = floating_workspaces

        total_wins = len(ws_clients)
        default_w = max(780, min(1300, int(mon_w * (0.70 if total_wins == 1 else 0.62))))
        default_h = max(520, min(820, int(mon_h * (0.70 if total_wins == 1 else 0.64))))

        anchors = [
            (mon_x + 35, mon_y + 55),                                           # Top-Left
            (mon_x + mon_w - default_w - 35, mon_y + mon_h - default_h - 30),  # Bottom-Right
            (mon_x + mon_w - default_w - 35, mon_y + 55),                       # Top-Right
            (mon_x + 35, mon_y + mon_h - default_h - 30),                       # Bottom-Left
            (mon_x + int((mon_w - default_w) / 2), mon_y + 55),                 # Top-Center
            (mon_x + int((mon_w - default_w) / 2), mon_y + mon_h - default_h - 30), # Bottom-Center
            (mon_x + int((mon_w - default_w) / 2), mon_y + int((mon_h - default_h) / 2)) # Center
        ]

        for idx, c in enumerate(ws_clients):
            addr = c.get("address")
            if not addr:
                continue

            w_class = c.get("class", "default")
            w_title = c.get("title", "")
            saved = cache.get(addr) or cache.get(w_class) or cache.get(f"{w_class}:{w_title}")

            lua_commands.append(f'hl.dispatch(hl.dsp.window.float({{ window = "address:{addr}", action = "on" }}))')

            if saved and "size" in saved and "at" in saved:
                w, h = saved["size"]
                x, y = saved["at"]
                w = max(450, min(w, mon_w - 40))
                h = max(350, min(h, mon_h - 70))
                x = max(mon_x + 20, min(x, mon_x + mon_w - w - 20))
                y = max(mon_y + 45, min(y, mon_y + mon_h - h - 20))
            else:
                w = default_w
                h = default_h
                if total_wins == 1:
                    x = mon_x + int((mon_w - default_w) / 2)
                    y = mon_y + int((mon_h - default_h) / 2)
                else:
                    anchor_idx = idx % len(anchors)
                    ax, ay = anchors[anchor_idx]
                    cycle = idx // len(anchors)
                    x = max(mon_x + 20, min(ax + (cycle * 45), mon_x + mon_w - default_w - 20))
                    y = max(mon_y + 45, min(ay + (cycle * 35), mon_y + mon_h - default_h - 20))

            lua_commands.append(f'hl.dispatch(hl.dsp.window.resize({{ window = "address:{addr}", x = {int(w)}, y = {int(h)}, relative = false }}))')
            lua_commands.append(f'hl.dispatch(hl.dsp.window.move({{ window = "address:{addr}", x = {int(x)}, y = {int(y)}, relative = false }}))')

        if ws_clients:
            top_addr = ws_clients[-1].get("address")
            lua_commands.append(f'hl.dispatch(hl.dsp.focus({{ window = "address:{top_addr}" }}))')

        save_cache(cache)

    else:
        if str(cur_ws) in floating_workspaces:
            floating_workspaces.remove(str(cur_ws))
        cache["floating_workspaces"] = floating_workspaces

        for c in ws_clients:
            addr = c.get("address")
            w_class = c.get("class", "default")
            w_title = c.get("title", "")
            cur_size = c.get("size")
            cur_at = c.get("at")
            if addr and cur_size and cur_at:
                cache[addr] = {"size": cur_size, "at": cur_at}
                cache[w_class] = {"size": cur_size, "at": cur_at}
                cache[f"{w_class}:{w_title}"] = {"size": cur_size, "at": cur_at}
                lua_commands.append(f'hl.dispatch(hl.dsp.window.float({{ window = "address:{addr}", action = "off" }}))')

        save_cache(cache)

    if lua_commands:
        run_eval("\n".join(lua_commands))

if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "single"
    if mode == "all":
        toggle_all()
    else:
        toggle_single()
