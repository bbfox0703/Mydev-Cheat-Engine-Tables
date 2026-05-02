# list_paloc.py
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crimson_rs

GAME = r"D:\SteamLibrary\steamapps\common\Crimson Desert"

for n in range(20, 36):
    g = f"{n:04d}"
    pamt_path = os.path.join(GAME, g, "0.pamt")
    if not os.path.isfile(pamt_path):
        continue
    try:
        with open(pamt_path, "rb") as f:
            pamt = crimson_rs.parse_pamt_bytes(f.read())
    except Exception as e:
        print(f"[{g}] parse error: {e}")
        continue

    hits = []
    for d in pamt["directories"]:
        dpath = d.get("path") or d.get("name") or ""
        for f in d.get("files", []):
            fname = f["name"]
            if fname.endswith(".paloc"):
                hits.append(f"{dpath}/{fname}".lstrip("/"))
    if hits:
        print(f"\n[{g}]  ({len(hits)} paloc files)")
        for h in hits:
            print(f"  {h}")