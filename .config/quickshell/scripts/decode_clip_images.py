"""
Decode binary clipboard entries from cliphist into temporary image files.
Outputs a JSON mapping of entry ID -> file path.
"""
import os
import subprocess
import json
import re

PREVIEW_DIR = "/tmp/cliphist_previews"

def main():
    os.makedirs(PREVIEW_DIR, exist_ok=True)

    result = subprocess.run(["cliphist", "list"], capture_output=True)
    if result.returncode != 0:
        print("{}")
        return

    raw = result.stdout.decode("utf-8", errors="replace")

    mapping = {}
    binary_pattern = re.compile(r'\[\[\s*binary data.*?\]\]')

    for line in raw.split("\n"):
        line = line.strip()
        if not line:
            continue

        tab_idx = line.find("\t")
        if tab_idx == -1:
            continue

        entry_id = line[:tab_idx].strip()
        content = line[tab_idx + 1:].strip()

        if binary_pattern.search(content):
            ext = "png"
            if "jpg" in content or "jpeg" in content:
                ext = "jpg"
            elif "gif" in content:
                ext = "gif"
            elif "webp" in content:
                ext = "webp"

            out_path = os.path.join(PREVIEW_DIR, f"{entry_id}.{ext}")

            if not os.path.exists(out_path):
                try:

                    original_line = f"{entry_id}\t{content}"
                    decode = subprocess.run(
                        ["cliphist", "decode"],
                        input=original_line.encode("utf-8"),
                        capture_output=True,
                        timeout=5
                    )
                    if decode.returncode == 0 and len(decode.stdout) > 0:
                        with open(out_path, "wb") as f:
                            f.write(decode.stdout)
                except Exception:
                    continue

            if os.path.exists(out_path):
                mapping[entry_id] = "file://" + out_path

    print(json.dumps(mapping))

if __name__ == "__main__":
    main()
