import time
import os
import sys
import json
import signal
import psutil

def handle_exit(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGTERM, handle_exit)
signal.signal(signal.SIGINT, handle_exit)
if hasattr(signal, 'SIGHUP'):
    signal.signal(signal.SIGHUP, handle_exit)

def get_stats():
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    cpu_pct = psutil.cpu_percent(interval=None)
    cpu_freq = psutil.cpu_freq()
    freq_ghz = round(cpu_freq.current / 1000, 2) if cpu_freq else 0.0

    raw = {}
    for p in psutil.process_iter(['name', 'cpu_percent', 'memory_percent', 'memory_info', 'memory_full_info']):
        try:
            info = p.info
            name = info['name'] or 'process'
            cpu = info['cpu_percent'] or 0.0
            mem_pct = info['memory_percent'] or 0.0

            mem_full = info.get('memory_full_info')
            if mem_full and hasattr(mem_full, 'uss') and mem_full.uss:
                rss = mem_full.uss / (1024 * 1024)
            else:
                rss = (info['memory_info'].rss if info.get('memory_info') else 0) / (1024 * 1024)

            if name in raw:
                raw[name]['cpu'] += cpu
                raw[name]['mem'] += mem_pct
                raw[name]['rss_mb'] += rss
                raw[name]['count'] += 1
            else:
                raw[name] = {'name': name, 'cpu': cpu, 'mem': mem_pct, 'rss_mb': rss, 'count': 1}
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass

    grouped = list(raw.values())
    for g in grouped:
        g['cpu'] = round(g['cpu'], 1)
        g['mem'] = round(g['mem'], 1)
        g['rss_mb'] = round(g['rss_mb'], 1)
        g['score'] = round(g['cpu'] + g['mem'], 1)
    grouped.sort(key=lambda x: x['score'], reverse=True)

    return {
        'cpu': {'usage': round(cpu_pct, 1), 'cores': psutil.cpu_count(logical=True), 'freq': freq_ghz},
        'memory': {'used_gb': round(mem.used / (1024**3), 2), 'total_gb': round(mem.total / (1024**3), 2), 'usage': round(mem.percent, 1)},
        'swap': {'used_gb': round(swap.used / (1024**3), 2), 'total_gb': round(swap.total / (1024**3), 2), 'usage': round(swap.percent, 1)},
        'top_apps': grouped[:10]
    }

def main():
    psutil.cpu_percent(interval=None)

    while True:
        try:
            if os.getppid() == 1:
                sys.exit(0)

            data = get_stats()
            sys.stdout.write(json.dumps(data) + "\n")
            sys.stdout.flush()
            time.sleep(1.5)
        except (KeyboardInterrupt, BrokenPipeError, IOError, OSError):
            sys.exit(0)

if __name__ == "__main__":
    main()
