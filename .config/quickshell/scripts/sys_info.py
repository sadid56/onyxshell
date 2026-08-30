#!/usr/bin/env python3

import os
import platform
import subprocess
import json
import shutil
import re

DISTRO_ASCII = {
    "arch": """       -`
      .o+`
     `ooo/
    `+oooo:
   `+oooooo:
   -+oooooo+:
 `/:-:++oooo+:
 `/++++/+++++++:
`/++++++++++++++:
`/+++ooooooooooooo/`
./ooosssso++osssssso`
.oooosssso-````/osssss+`
-osssssso.      :ssssssso.
:osssssss/        osssso+++.
/osssssss/        +sssssoo/-
`/ossssso+/:-    -:/+osssso+-
`+sso+:-`            `.-/+oso:
`++:.                     `-/+/
.`                           `/""",
    "fedora": """      _____
     /   __)\\
    |  /  \\ \\
 __ | |    | |
/ ___\\ |  / /
\\ \\___/ |__/_\\
 \\____/""",
    "ubuntu": """         _
     ---(_)
 _/  ___  \\
(_) /   \\
   | (_) |
 _\\  ___  /
(_)  ---""",
    "debian": """  _____
 /  __ \\
|  /    |
|  \\___-
-_
  --_""",
    "nixos": """  \\\\  \\\\ //
 ==\\\\__\\\\/ //
   //   \\\\//
==//     //=="""
}

def get_system_info():
    info = {
        "osName": "Linux",
        "distroId": "linux",
        "asciiLogo": "",
        "host": platform.node(),
        "cpu": "Generic Processor",
        "gpus": [],
        "ram": "Unknown",
        "ramUsed": "",
        "disk": "Unknown",
        "kernel": f"Linux {platform.release()}",
        "arch": "x86_64" if platform.machine() in ["x86_64", "AMD64"] else platform.machine(),
        "packages": "",
        "shell": os.path.basename(os.environ.get("SHELL", "bash")),
        "uptime": "Active",
        "wm": "Wayland (Hyprland)",
        "dm": "Wayland",
        "hyprlandVersion": "Hyprland",
        "quickshellVersion": "Quickshell"
    }

    try:
        hv = subprocess.check_output(["hyprctl", "version"], text=True, timeout=1).splitlines()[0]
        m = re.search(r"Hyprland\s+([\d\.]+)", hv)
        if m:
            info["hyprlandVersion"] = f"Hyprland {m.group(1)}"
        else:
            info["hyprlandVersion"] = hv.split(" built ")[0].strip()
    except Exception:
        info["hyprlandVersion"] = "Hyprland 0.56.2"

    try:
        qv = subprocess.check_output(["quickshell", "--version"], text=True, timeout=1).splitlines()[0]
        m = re.search(r"Quickshell\s+([\d\.]+)", qv)
        if m:
            info["quickshellVersion"] = f"Quickshell {m.group(1)}"
        else:
            info["quickshellVersion"] = qv.split("(")[0].strip()
    except Exception:
        info["quickshellVersion"] = "Quickshell 0.3.1"

    try:
        if os.path.exists("/etc/os-release"):
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        info["osName"] = line.split("=", 1)[1].strip().strip('"')
                    elif line.startswith("ID="):
                        info["distroId"] = line.split("=", 1)[1].strip().strip('"').lower()
        if info["distroId"] in DISTRO_ASCII:
            info["asciiLogo"] = DISTRO_ASCII[info["distroId"]]
    except Exception:
        pass

    if shutil.which("fastfetch"):
        try:
            res = subprocess.run(["fastfetch", "--json"], capture_output=True, text=True, timeout=2)
            if res.returncode == 0:
                parsed = json.loads(res.stdout)
                for item in parsed:
                    t = item.get("type")
                    r = item.get("result")
                    if not r:
                        continue
                    if t == "Host" and isinstance(r, dict):
                        info["host"] = r.get("name") or info["host"]
                    elif t == "CPU" and isinstance(r, dict):
                        cpu_name = r.get("cpu", "")
                        cores = r.get("cores", {}).get("logical", "")
                        freq = r.get("frequency", {}).get("max", 0)
                        freq_str = f" @ {freq/1000.0:.2f} GHz" if freq > 0 else ""
                        cores_str = f" ({cores})" if cores else ""
                        info["cpu"] = f"{cpu_name}{cores_str}{freq_str}".strip()
                    elif t == "GPU" and isinstance(r, list):
                        glist = []
                        for g in r:
                            gname = g.get("name", "")
                            gvendor = g.get("vendor", "")
                            gtype = g.get("type", "")
                            type_tag = f" [{gtype}]" if gtype else ""
                            if gname:
                                if gvendor and not gname.startswith(gvendor):
                                    glist.append(f"{gvendor} {gname}{type_tag}")
                                else:
                                    glist.append(f"{gname}{type_tag}")
                        if glist:
                            info["gpus"] = glist
                    elif t == "OS" and isinstance(r, dict):
                        info["osName"] = r.get("name", info["osName"])
                    elif t == "Kernel" and isinstance(r, dict):
                        info["kernel"] = f"Linux {r.get('release', platform.release())}"
                    elif t == "Packages" and isinstance(r, dict):
                        total = r.get("all", 0)
                        mgr = "pacman" if "pacman" in r else "pkgs"
                        info["packages"] = f"{total} ({mgr})"
                    elif t == "LM" and isinstance(r, dict):
                        info["dm"] = f"{r.get('service', 'greetd')} ({r.get('type', 'Wayland')})"
                    elif t == "WM" and isinstance(r, dict):
                        info["wm"] = f"{r.get('prettyName', 'Hyprland')} {r.get('version', '')} ({r.get('protocolName', 'Wayland')})"
        except Exception:
            pass

    if not info["gpus"]:
        try:
            lspci = subprocess.check_output(["lspci"], text=True)
            for line in lspci.splitlines():
                if "VGA" in line or "3D" in line or "Display" in line:
                    parts = line.split(":", 2)
                    if len(parts) > 2:
                        g = parts[2].strip().replace("Corporation ", "").replace("Advanced Micro Devices, Inc. ", "")
                        info["gpus"].append(g)
        except Exception:
            pass
        if not info["gpus"]:
            info["gpus"] = ["Integrated Graphics"]

    if not info["host"] or info["host"] == "Linux Device":
        try:
            if os.path.exists("/sys/devices/virtual/dmi/id/product_name"):
                with open("/sys/devices/virtual/dmi/id/product_name") as f:
                    info["host"] = f.read().strip()
        except Exception:
            info["host"] = platform.node()

    try:
        with open("/proc/meminfo") as f:
            lines = f.read()
            total_kb = int(re.search(r"MemTotal:\s+(\d+)", lines).group(1))
            avail_kb = int(re.search(r"MemAvailable:\s+(\d+)", lines).group(1))
            total_gb = total_kb / (1024 * 1024)
            used_gb = (total_kb - avail_kb) / (1024 * 1024)
            info["ram"] = f"{total_gb:.2f} GiB"
            info["ramUsed"] = f"{used_gb:.2f} GiB"
    except Exception:
        pass

    try:
        st = os.statvfs("/")
        total_gb = (st.f_blocks * st.f_frsize) / (1024 ** 3)
        free_gb = (st.f_bavail * st.f_frsize) / (1024 ** 3)
        used_gb = total_gb - free_gb
        pct = int((used_gb / total_gb) * 100) if total_gb > 0 else 0
        info["disk"] = f"{total_gb:.2f} GiB ({pct}%)"
    except Exception:
        pass

    try:
        up = subprocess.check_output(["uptime", "-p"], text=True).strip()
        if up.startswith("up "):
            up = up[3:]
        info["uptime"] = up
    except Exception:
        pass

    return info

if __name__ == "__main__":
    print(json.dumps(get_system_info()))
