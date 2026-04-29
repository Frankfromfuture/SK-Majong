#!/usr/bin/env python3
"""
Cut green screen PNG assets into modular parts for warlord1.

If Pillow is missing:
    pip install Pillow
"""

from __future__ import annotations

import json
from collections import deque
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit(
        "Pillow is required. Please run: pip install Pillow"
    ) from exc


ROOT = Path(__file__).resolve().parents[1]
INPUT_DIR = ROOT / "characters" / "warlord1" / "assets" / "raw_generated"
OUTPUT_DIR = ROOT / "characters" / "warlord1" / "assets" / "cut"
INDEX_PATH = OUTPUT_DIR / "cut_index.json"

GREEN_THRESHOLD = 0.20
MIN_ALPHA = 10
PADDING = 12  # 8~16 recommended
MIN_COMPONENT_PIXELS = 80


@dataclass
class Rect:
    x: int
    y: int
    w: int
    h: int

    @property
    def x2(self) -> int:
        return self.x + self.w

    @property
    def y2(self) -> int:
        return self.y + self.h


def is_green(px: Tuple[int, int, int, int]) -> bool:
    r, g, b, _a = px
    dr = abs((r / 255.0) - 0.0)
    dg = abs((g / 255.0) - 1.0)
    db = abs((b / 255.0) - 0.0)
    near_key_green = (dr + dg + db) <= GREEN_THRESHOLD and g >= 140
    dominant_green = g >= 70 and g > int(r * 1.2) and g > int(b * 1.2) and (g - max(r, b)) >= 18
    return near_key_green or dominant_green


def clear_green(pixels: List[Tuple[int, int, int, int]]) -> List[Tuple[int, int, int, int]]:
    out = []
    for r, g, b, a in pixels:
        if is_green((r, g, b, a)):
            out.append((r, g, b, 0))
        else:
            out.append((r, g, b, a))
    return out


def connected_components(img: Image.Image) -> List[Rect]:
    w, h = img.size
    px = img.load()
    visited = [False] * (w * h)
    rects: List[Rect] = []

    def idx(x: int, y: int) -> int:
        return y * w + x

    for y in range(h):
        for x in range(w):
            i = idx(x, y)
            if visited[i]:
                continue
            visited[i] = True
            if px[x, y][3] <= MIN_ALPHA:
                continue

            q = deque([(x, y)])
            min_x = max_x = x
            min_y = max_y = y

            while q:
                cx, cy = q.pop()
                min_x = min(min_x, cx)
                min_y = min(min_y, cy)
                max_x = max(max_x, cx)
                max_y = max(max_y, cy)

                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if nx < 0 or nx >= w or ny < 0 or ny >= h:
                        continue
                    ni = idx(nx, ny)
                    if visited[ni]:
                        continue
                    visited[ni] = True
                    if px[nx, ny][3] <= MIN_ALPHA:
                        continue
                    q.append((nx, ny))

            rect = Rect(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
            if rect.w * rect.h >= MIN_COMPONENT_PIXELS:
                rects.append(rect)

    return rects


def pad_rect(rect: Rect, width: int, height: int, pad: int) -> Rect:
    x = max(0, rect.x - pad)
    y = max(0, rect.y - pad)
    x2 = min(width, rect.x2 + pad)
    y2 = min(height, rect.y2 + pad)
    return Rect(x, y, x2 - x, y2 - y)


def process_file(path: Path) -> List[Dict]:
    img = Image.open(path).convert("RGBA")
    pixels = clear_green(list(img.getdata()))
    img.putdata(pixels)

    parts = connected_components(img)
    basename = path.stem.replace(" ", "_").lower()
    items: List[Dict] = []

    for i, rect in enumerate(parts, start=1):
        padded = pad_rect(rect, img.width, img.height, PADDING)
        crop = img.crop((padded.x, padded.y, padded.x2, padded.y2))
        out_name = f"{basename}_{i:03d}.png"
        out_path = OUTPUT_DIR / out_name
        crop.save(out_path)
        items.append(
            {
                "source_file": str(path.relative_to(ROOT)).replace("\\", "/"),
                "output_file": str(out_path.relative_to(ROOT)).replace("\\", "/"),
                "component_index": i,
                "crop_rect": {"x": padded.x, "y": padded.y, "w": padded.w, "h": padded.h},
                "size": {"w": padded.w, "h": padded.h},
            }
        )
    return items


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for old_file in OUTPUT_DIR.glob("*.png"):
        old_file.unlink()
    all_items: List[Dict] = []
    sources = sorted([p for p in INPUT_DIR.glob("*.png") if p.is_file()])
    for src in sources:
        all_items.extend(process_file(src))

    payload = {
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "items": all_items,
    }
    INDEX_PATH.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    print(
        f"[OK] sources={len(sources)} cuts={len(all_items)} index={INDEX_PATH.relative_to(ROOT)}"
    )


if __name__ == "__main__":
    main()
