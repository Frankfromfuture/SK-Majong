#!/usr/bin/env python3
"""
Build a best-effort warlord1_parts_map.json from cut_index.json.

Heuristic:
1) Group by source sheet.
2) Keep top-N by area for rider/horse/weapon/effects.
3) Sort selected parts by (y, x) reading order.
4) Assign in prompt order.
"""

from __future__ import annotations

import json
from copy import deepcopy
from pathlib import Path
from typing import Dict, List


ROOT = Path(__file__).resolve().parents[1]
CUT_INDEX = ROOT / "characters" / "warlord1" / "assets" / "cut" / "cut_index.json"
MAP_PATH = ROOT / "characters" / "warlord1" / "assets" / "parts" / "warlord1_parts_map.json"

RIDER_KEYS = [
    "helmet_front", "golden_crown", "helmet_back", "hidden_face_shadow", "torso_armor",
    "waist_armor", "cape_back", "left_shoulder_guard", "left_upper_arm", "left_lower_arm",
    "left_hand", "right_shoulder_guard", "right_upper_arm", "right_lower_arm", "right_hand",
    "left_upper_leg", "left_lower_leg", "left_boot", "right_upper_leg", "right_lower_leg",
    "right_boot", "saddle_connection_cloth", "back_banner_small", "armor_skirt_left", "armor_skirt_right",
]

HORSE_KEYS = [
    "horse_head", "horse_neck", "horse_body", "horse_chest_armor", "horse_saddle",
    "horse_reins", "horse_tail", "front_left_upper_leg", "front_left_lower_leg", "front_left_hoof",
    "front_right_upper_leg", "front_right_lower_leg", "front_right_hoof",
    "back_left_upper_leg", "back_left_lower_leg", "back_left_hoof",
    "back_right_upper_leg", "back_right_lower_leg", "back_right_hoof", "horse_cloth_armor", "horse_mane",
]

WEAPON_KEYS = [
    "long_spear_full", "long_spear_tip", "long_spear_shaft", "long_spear_back_end",
    "spear_motion_blur_1", "spear_motion_blur_2", "spear_motion_blur_3",
    "spear_charge_glow", "spear_thrust_line", "spear_slash_arc",
]

EFFECT_SEQUENCE = [
    ("spear_thrust_flash", 3),
    ("spear_slash_arc", 3),
    ("impact_spark", 3),
    ("horse_charge_dust", 3),
    ("ground_crack", 2),
    ("red_command_aura", 3),
    ("black_wind_trail", 3),
]


def load_json(path: Path) -> Dict:
    return json.loads(path.read_text(encoding="utf-8"))


def output_name(item: Dict) -> str:
    return Path(item["output_file"]).name


def area(item: Dict) -> int:
    return int(item["size"]["w"]) * int(item["size"]["h"])


def reading_key(item: Dict) -> tuple[int, int, int]:
    r = item["crop_rect"]
    return int(r["y"]), int(r["x"]), -area(item)


def choose_items(items: List[Dict], n: int) -> List[Dict]:
    top = sorted(items, key=area, reverse=True)[:n]
    return sorted(top, key=reading_key)


def assign_keys(target: Dict[str, str], keys: List[str], picks: List[Dict]) -> None:
    for i, k in enumerate(keys):
        target[k] = output_name(picks[i]) if i < len(picks) else ""


def main() -> None:
    idx = load_json(CUT_INDEX)
    src: Dict[str, List[Dict]] = {}
    for it in idx.get("items", []):
        source_name = Path(it["source_file"]).name
        src.setdefault(source_name, []).append(it)

    data = load_json(MAP_PATH)
    out = deepcopy(data)

    rider_items = src.get("warlord1_parts_sheet.png", [])
    horse_items = src.get("warlord1_horse_parts_sheet.png", [])
    weapon_items = src.get("warlord1_weapon_sheet.png", [])
    effects_items = src.get("warlord1_effects_sheet.png", [])

    rider_pick = choose_items(rider_items, len(RIDER_KEYS))
    horse_pick = choose_items(horse_items, len(HORSE_KEYS))
    weapon_pick = choose_items(weapon_items, len(WEAPON_KEYS))
    effects_pick = choose_items(effects_items, 20)

    assign_keys(out["rider"], RIDER_KEYS, rider_pick)
    assign_keys(out["horse"], HORSE_KEYS, horse_pick)
    assign_keys(out["weapon"], WEAPON_KEYS, weapon_pick)

    cursor = 0
    for effect_id, count in EFFECT_SEQUENCE:
        out["effects"][effect_id] = [output_name(x) for x in effects_pick[cursor: cursor + count]]
        cursor += count

    MAP_PATH.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "[OK] rider=%d horse=%d weapon=%d effects=%d map=%s"
        % (len(rider_pick), len(horse_pick), len(weapon_pick), len(effects_pick), MAP_PATH.relative_to(ROOT))
    )


if __name__ == "__main__":
    main()
