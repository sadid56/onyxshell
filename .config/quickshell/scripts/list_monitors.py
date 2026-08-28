#!/usr/bin/env python3

import json
import re
import subprocess
import sys

def get_monitors():
    try:
        proc = subprocess.run(
            ["hyprctl", "monitors", "all", "-j"],
            capture_output=True,
            text=True,
            check=True
        )
        data = json.loads(proc.stdout)
    except Exception:
        try:
            proc = subprocess.run(
                ["hyprctl", "monitors", "-j"],
                capture_output=True,
                text=True,
                check=True
            )
            data = json.loads(proc.stdout)
        except Exception as e:
            return []

    monitors = []
    for m in data:
        name = m.get("name", "")
        desc = m.get("description", "") or m.get("model", "") or name
        width = m.get("width", 1920)
        height = m.get("height", 1080)
        refresh_raw = m.get("refreshRate", 60.0)
        refresh_rounded = round(float(refresh_raw))
        scale = m.get("scale", 1.0)
        current_res = f"{width}x{height}"

        raw_modes = m.get("availableModes", [])
        res_map = {}

        for mode_str in raw_modes:

            match = re.match(r"^(\d+x\d+)@([\d\.]+)Hz", mode_str.strip())
            if match:
                res = match.group(1)
                hz = round(float(match.group(2)))
                if res not in res_map:
                    res_map[res] = []
                if hz not in res_map[res]:
                    res_map[res].append(hz)

        def res_sort_key(r):
            try:
                w, h = map(int, r.split("x"))
                return w * h
            except Exception:
                return 0

        sorted_res = sorted(res_map.keys(), key=res_sort_key, reverse=True)
        if not sorted_res and current_res:
            sorted_res = [current_res]
            res_map[current_res] = [refresh_rounded]

        for r in res_map:
            res_map[r].sort(reverse=True)

        monitors.append({
            "name": name,
            "description": desc,
            "currentRes": current_res,
            "currentHz": refresh_rounded,
            "currentScale": scale,
            "resolutions": sorted_res,
            "modes": res_map,
            "rawModes": raw_modes
        })

    return monitors

if __name__ == "__main__":
    result = get_monitors()
    print(json.dumps(result, indent=2))
