from pathlib import Path
from PIL import Image
import importlib.util
import re

ROOT = Path(__file__).resolve().parents[1]
atlas_path = ROOT / "assets" / "generated" / "ui_atlas.png"
manifest_path = ROOT / "assets" / "generated" / "ui_atlas.lua"

image = Image.open(atlas_path)
text = manifest_path.read_text(encoding="utf-8")
frames = {}
for name, x, y, w, h in re.findall(r"(\w+) = \{ x = (\d+), y = (\d+), w = (\d+), h = (\d+) \}", text):
    frames[name] = tuple(map(int, (x, y, w, h)))

expected = {
    "button_red": (280, 56),
    "button_green": (280, 56),
    "panel_jade": (220, 64),
    "tile_base": (64, 88),
    "tile_selected": (64, 88),
    "coin_stack": (96, 48),
}

for name, size in expected.items():
    assert name in frames, f"missing frame {name}"
    assert frames[name][2:] == size, f"{name} expected {size}, got {frames[name][2:]}"
    x, y, w, h = frames[name]
    assert x + w <= image.width and y + h <= image.height, f"{name} outside atlas"

print("asset manifest ok:", len(frames), "frames", image.size)
