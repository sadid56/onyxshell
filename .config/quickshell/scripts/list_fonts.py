#!/usr/bin/env python3

import subprocess
import json
import re

def get_installed_fonts():
    try:
        out = subprocess.check_output(["fc-list", ":", "family"], text=True)
    except Exception:
        out = ""

    families = set()
    skip_suffixes = [
        " Thin", " Light", " ExtraLight", " UltraLight", " Medium",
        " SemiBold", " DemiBold", " Bold", " ExtraBold", " Black",
        " Heavy", " Italic", " Oblique", " Condensed", " SemiCondensed",
        " ExtraCondensed", " Regular", " Book"
    ]

    for line in out.splitlines():
        parts = [p.strip() for p in line.split(",") if p.strip()]
        for name in parts:
            if not name or name.startswith("@") or name.startswith("."):
                continue
            clean = name
            for s in skip_suffixes:
                if clean.endswith(s):
                    clean = clean[:-len(s)].strip()
            if clean and len(clean) > 1:
                families.add(clean)

    sorted_list = sorted(list(families), key=lambda s: s.lower())

    curated = [
        "JetBrainsMono Nerd Font",
        "JetBrainsMono Nerd Font Mono",
        "JetBrainsMono Nerd Font Propo",
        "FiraCode Nerd Font",
        "FiraCode Nerd Font Mono",
        "Hack Nerd Font",
        "Cascadia Code",
        "Inter",
        "Roboto",
        "Noto Sans",
        "Noto Serif",
        "DejaVu Sans",
        "DejaVu Sans Mono",
        "Liberation Sans",
        "Liberation Mono",
        "Adwaita Sans",
        "Adwaita Mono",
        "Ubuntu",
        "Cantarell"
    ]

    installed_curated = [f for f in curated if f in sorted_list]
    remaining = [f for f in sorted_list if f not in installed_curated]

    clean_remaining = []
    regional_scripts = ["Ahom", "Anatolian", "Arab", "Balinese", "Bamum", "Bassa", "Batak", "Bhaiksuki", "Brahmi", "Buginese", "Buhid", "Carian", "Chakma", "Cham", "Cherokee", "Coptic", "Cuneiform", "Cypriot", "Cypro", "Deseret", "Dogra", "Duployan", "Egyptian", "Elbasan", "Elymaic", "Ethiopic", "Glagolitic", "Gothic", "Grantha", "Hanifi", "Hatran", "Imperial", "Indic", "Inscriptional", "Javanese", "Kaithi", "Kayah", "Kharoshthi", "Khojki", "Khudawadi", "Lepcha", "Limbu", "Linear", "Lisu", "Lycian", "Lydian", "Mahajani", "Mandaic", "Manichaean", "Marchen", "Masaram", "Medefaidrin", "Mende", "Meroitic", "Miao", "Modi", "Mro", "Multani", "Nabataean", "Nandinagari", "Newa", "Nushu", "Nko", "Ogham", "Ol Chiki", "Old", "Osage", "Osmanya", "Pahawh", "Palmyrene", "Pau Cin", "Phags", "Phoenician", "Psalter", "Rejang", "Runic", "Samaritan", "Saurashtra", "Sharada", "Shavian", "Siddham", "SignWriting", "Sogdian", "Sora", "Soyombo", "Sundanese", "Sunuwar", "Syloti", "Syriac", "Tagalog", "Tagbanwa", "Tai", "Takri", "Tangsa", "Tangut", "Thaana", "Tifinagh", "Tirhuta", "Ugaritic", "Vai", "Vithkuqi", "Wancho", "Warang", "Yezidi", "Zanabazar"]

    for f in remaining:
        fl = f.lower()
        if any(r.lower() in fl for r in regional_scripts):
            continue
        clean_remaining.append(f)

    all_fonts = installed_curated + clean_remaining

    results = []
    for f in all_fonts:
        fl = f.lower()
        is_nerd = "nerd" in fl or " nf" in fl or " nfm" in fl
        is_mono = "mono" in fl or "code" in fl or "nerd font" in fl or "typewriter" in fl or "terminal" in fl
        results.append({
            "family": f,
            "isNerd": is_nerd,
            "isMono": is_mono
        })

    return results

if __name__ == "__main__":
    print(json.dumps(get_installed_fonts()))
