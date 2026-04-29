#!/usr/bin/env python3
"""
Generate a draft warlord1_parts_map.json from cut PNG filenames.

Usage:
    python3 tools/generate_warlord1_map_draft.py
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List


ROOT = Path(__file__).resolve().parents[1]
CUT_DIR = ROOT / "characters" / "warlord1" / "assets" / "cut"
MAP_PATH = ROOT / "characters" / "warlord1" / "assets" / "parts" / "warlord1_parts_map.json"


def load_map() -> Dict:
    return json.loads(MAP_PATH.read_text(encoding="utf-8"))


def cut_pngs() -> List[str]:
    return sorted([p.name for p in CUT_DIR.glob("*.png") if p.is_file()])


def maybe_fill_object(section: Dict[str, str], files: List[str]) -> None:
    for key, value in section.items():
        if value:
            continue
        key_l = key.lower()
        for file_name in files:
            if key_l in file_name.lower():
                section[key] = file_name
                break


def maybe_fill_effects(section: Dict[str, List[str]], files: List[str]) -> None:
    for key, frames in section.items():
        if frames:
            continue
        key_l = key.lower()
        hits = [f for f in files if key_l in f.lower()]
        if hits:
            section[key] = sorted(hits)


def main() -> None:
    data = load_map()
    files = cut_pngs()
    maybe_fill_object(data.get("rider", {}), files)
    maybe_fill_object(data.get("horse", {}), files)
    maybe_fill_object(data.get("weapon", {}), files)
    maybe_fill_effects(data.get("effects", {}), files)
    MAP_PATH.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"[OK] files={len(files)} map={MAP_PATH.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
