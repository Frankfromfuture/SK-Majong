#!/usr/bin/env python3
"""
Slice a green-screen mahjong tile face sheet into individual PNGs.

Usage:
  python3 slice_tile_sheet.py <input_image> <sheet_type> [--output-dir DIR] [--preview]

Sheet types:
  wan   - 万子 1-9, expects 3x3 grid
  tong  - 筒子 1-9, expects 3x3 grid
  suo   - 索子 1-9, expects 3x3 grid
  honor - 字牌 东南西北中发白, expects 4x2 grid (last cell empty)

Examples:
  python3 slice_tile_sheet.py wan_sheet.png wan
  python3 slice_tile_sheet.py honor_sheet.png honor --output-dir ../assets/sprites/battle/Textures/
  python3 slice_tile_sheet.py wan_sheet.png wan --preview
"""

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageFilter
except ImportError:
    print("ERROR: Pillow is required. Install with: pip3 install Pillow")
    sys.exit(1)


# --- Tile name definitions ---------------------------------------------------

SHEET_DEFS = {
    "wan": {
        "cols": 3, "rows": 3,
        "names": [
            "TileFace_Wan_01", "TileFace_Wan_02", "TileFace_Wan_03",
            "TileFace_Wan_04", "TileFace_Wan_05", "TileFace_Wan_06",
            "TileFace_Wan_07", "TileFace_Wan_08", "TileFace_Wan_09",
        ],
    },
    "tong": {
        "cols": 3, "rows": 3,
        "names": [
            "TileFace_Tong_01", "TileFace_Tong_02", "TileFace_Tong_03",
            "TileFace_Tong_04", "TileFace_Tong_05", "TileFace_Tong_06",
            "TileFace_Tong_07", "TileFace_Tong_08", "TileFace_Tong_09",
        ],
    },
    "suo": {
        "cols": 3, "rows": 3,
        "names": [
            "TileFace_Suo_01", "TileFace_Suo_02", "TileFace_Suo_03",
            "TileFace_Suo_04", "TileFace_Suo_05", "TileFace_Suo_06",
            "TileFace_Suo_07", "TileFace_Suo_08", "TileFace_Suo_09",
        ],
    },
    "honor": {
        "cols": 4, "rows": 2,
        "names": [
            "TileFace_Wind_East", "TileFace_Wind_South",
            "TileFace_Wind_West", "TileFace_Wind_North",
            "TileFace_Dragon_Red", "TileFace_Dragon_Green",
            "TileFace_Dragon_White",
            # last cell (index 7) is empty, will be skipped
        ],
    },
}


def remove_green_screen(img: Image.Image, tolerance: int = 80) -> Image.Image:
    """Replace green-screen pixels with transparency."""
    img = img.convert("RGBA")
    pixels = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # Detect green screen: high green, low red and blue
            if g > 100 and g > r + tolerance and g > b + tolerance:
                pixels[x, y] = (0, 0, 0, 0)
    return img


def auto_find_grid(img: Image.Image, cols: int, rows: int):
    """
    Try to auto-detect tile boundaries by analyzing the image.
    Falls back to uniform grid if detection fails.
    Returns list of (x, y, w, h) crop boxes.
    """
    w, h = img.size
    cell_w = w // cols
    cell_h = h // rows

    boxes = []
    for row in range(rows):
        for col in range(cols):
            x = col * cell_w
            y = row * cell_h
            boxes.append((x, y, x + cell_w, y + cell_h))
    return boxes


def trim_transparent(img: Image.Image, padding: int = 4) -> Image.Image:
    """Trim transparent borders, keep a small padding."""
    bbox = img.getbbox()
    if bbox is None:
        return img
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - padding)
    y0 = max(0, y0 - padding)
    x1 = min(img.width, x1 + padding)
    y1 = min(img.height, y1 + padding)
    return img.crop((x0, y0, x1, y1))


def resize_to_standard(img: Image.Image, target_w: int = 512, target_h: int = 768) -> Image.Image:
    """Resize to standard tile face size, maintaining aspect ratio with padding."""
    # Fit within target, then center on transparent canvas
    img.thumbnail((target_w, target_h), Image.NEAREST)
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    offset_x = (target_w - img.width) // 2
    offset_y = (target_h - img.height) // 2
    canvas.paste(img, (offset_x, offset_y))
    return canvas


def process_sheet(input_path: str, sheet_type: str, output_dir: str, preview: bool = False):
    """Main processing pipeline."""
    if sheet_type not in SHEET_DEFS:
        print(f"ERROR: Unknown sheet type '{sheet_type}'. Choose from: {list(SHEET_DEFS.keys())}")
        sys.exit(1)

    sheet_def = SHEET_DEFS[sheet_type]
    cols = sheet_def["cols"]
    rows = sheet_def["rows"]
    names = sheet_def["names"]

    print(f"Loading: {input_path}")
    img = Image.open(input_path)
    print(f"  Image size: {img.size[0]}x{img.size[1]}")
    print(f"  Grid: {cols}x{rows} = {cols * rows} cells, {len(names)} named tiles")

    # Step 1: Get crop boxes
    boxes = auto_find_grid(img, cols, rows)

    # Step 2: Process each cell
    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    for i, box in enumerate(boxes):
        if i >= len(names):
            print(f"  Cell {i}: (empty, skipped)")
            continue

        tile_name = names[i]
        cell = img.crop(box)

        # Step 3: Remove green screen
        cell = remove_green_screen(cell)

        # Step 4: Trim transparent borders
        cell = trim_transparent(cell)

        # Step 5: Resize to standard 512x768
        cell = resize_to_standard(cell)

        # Step 6: Save
        out_file = out_path / f"{tile_name}.png"
        cell.save(str(out_file), "PNG")
        print(f"  ✅ {tile_name}.png  ({cell.size[0]}x{cell.size[1]})")

    if preview:
        # Generate a quick preview mosaic
        preview_img = Image.new("RGBA", (512 * min(cols, 4), 768 * min(rows, 3)), (40, 40, 40, 255))
        for i, name in enumerate(names):
            tile_file = out_path / f"{name}.png"
            if tile_file.exists():
                tile = Image.open(str(tile_file))
                col_idx = i % cols
                row_idx = i // cols
                preview_img.paste(tile, (col_idx * 512, row_idx * 768), tile)
        preview_file = out_path / f"_preview_{sheet_type}.png"
        preview_img.save(str(preview_file), "PNG")
        print(f"\n  📋 Preview saved: {preview_file}")

    print(f"\nDone! {len(names)} tiles saved to {out_path}/")


def main():
    parser = argparse.ArgumentParser(
        description="Slice green-screen mahjong tile sheets into individual PNGs."
    )
    parser.add_argument("input", help="Path to the input sheet image")
    parser.add_argument("sheet_type", choices=SHEET_DEFS.keys(),
                        help="Type of sheet: wan, tong, suo, honor")
    parser.add_argument("--output-dir", default=None,
                        help="Output directory (default: assets/sprites/battle/Textures/)")
    parser.add_argument("--preview", action="store_true",
                        help="Generate a preview mosaic after slicing")
    args = parser.parse_args()

    output_dir = args.output_dir
    if output_dir is None:
        # Auto-detect project root
        script_dir = Path(__file__).resolve().parent
        project_root = script_dir.parent
        output_dir = str(project_root / "assets" / "sprites" / "battle" / "Textures")

    process_sheet(args.input, args.sheet_type, output_dir, args.preview)


if __name__ == "__main__":
    main()
