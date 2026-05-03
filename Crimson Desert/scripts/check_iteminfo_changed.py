# check_iteminfo_changed.py — 放 CrimsonGameMods/ 底下
import os, sys, hashlib
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import crimson_rs

GAME = r"D:\SteamLibrary\steamapps\common\Crimson Desert"
raw = bytes(crimson_rs.extract_file(
    GAME, "0008", "gamedata/binary__/client/bin", "iteminfo.pabgb"))

print(f"size:   {len(raw):,} bytes")
print(f"sha256: {hashlib.sha256(raw).hexdigest()}")
print(f"first 8 bytes: {raw[:8].hex()}")