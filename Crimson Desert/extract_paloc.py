# extract_paloc.py  -- 用法: python extract_paloc.py
import json, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crimson_rs

GAME = r"D:\SteamLibrary\steamapps\common\Crimson Desert"
DIR  = "gamedata/stringtable/binary__"

# (lang_code, output_filename) — 想要的就解
TARGETS = [
    ("eng", "paloc_eng.json"),
    ("zho-tw", "paloc_zho-tw.json"),   # 繁中
    ("jpn", "paloc_jpn.json"),
    # ("kor", "paloc_kor.json"),
    # ("chs", "paloc_chs.json"),
]

# 0020~0035 全部試一遍，遇到就解（不同語系裝在不同 group）
GROUPS = [f"{n:04d}" for n in range(20, 36)]

for lang, out_name in TARGETS:
    fname = f"localizationstring_{lang}.paloc"
    raw = None
    for g in GROUPS:
        try:
            raw = bytes(crimson_rs.extract_file(GAME, g, DIR, fname))
            print(f"[{lang}] hit group {g}, {len(raw):,}B")
            break
        except Exception:
            continue
    if raw is None:
        print(f"[{lang}] not found in any group 0020-0035, skip")
        continue

    entries = crimson_rs.parse_paloc_bytes(raw)
    print(f"[{lang}] parsed {len(entries):,} entries -> {out_name}")

    # 過濾出 item name（id 末 8 bit = 0x70）→ {item_key: name}
    item_names = {}
    for e in entries:
        try:
            sid = int(e["string_key"])
        except (ValueError, TypeError):
            continue
        if sid & 0xFF != 0x70:
            continue
        item_key = sid >> 32
        item_names[item_key] = e["string_value"]

    with open(out_name, "w", encoding="utf-8") as f:
        json.dump(item_names, f, ensure_ascii=False, indent=2, sort_keys=True)
    print(f"[{lang}] wrote {len(item_names):,} item names")