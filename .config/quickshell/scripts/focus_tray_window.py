#!/usr/bin/env python3
import sys
import json
import subprocess

def focus_tray_window(tray_id, tray_title="", tray_icon=""):
    try:
        raw_clients = subprocess.check_output(["hyprctl", "clients", "-j"], timeout=1)
        clients = json.loads(raw_clients)
        
        search_terms = set()
        for raw in [tray_id, tray_title, tray_icon]:
            if not raw:
                continue
            s = str(raw).lower().strip()
            search_terms.add(s)
            
            cleaned = s.split(".")[-1].replace("-desktop", "").replace("_", "-")
            if cleaned:
                search_terms.add(cleaned)
                
            parts = s.split(".")
            for p in parts:
                if len(p) > 2 and p not in ["org", "com", "net", "io", "desktop", "client", "app"]:
                    search_terms.add(p)

        for c in clients:
            c_class = (c.get("class") or "").lower()
            c_init_class = (c.get("initialClass") or "").lower()
            c_title = (c.get("title") or "").lower()
            
            for term in search_terms:
                if len(term) < 2:
                    continue
                if (term in c_class or term in c_init_class or term in c_title or 
                    c_class in term or c_init_class in term):
                    addr = c.get("address")
                    if addr:
                        cmd = f'hl.dispatch(hl.dsp.focus({{ window = "address:{addr}" }}))'
                        subprocess.run(["hyprctl", "eval", cmd], timeout=1)
                        return True
    except Exception:
        pass
    return False

if __name__ == "__main__":
    t_id = sys.argv[1] if len(sys.argv) > 1 else ""
    t_title = sys.argv[2] if len(sys.argv) > 2 else ""
    t_icon = sys.argv[3] if len(sys.argv) > 3 else ""
    focus_tray_window(t_id, t_title, t_icon)
