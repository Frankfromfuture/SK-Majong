from pathlib import Path
from PIL import Image, ImageChops, ImageFilter, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
FULL_SOURCE = Path("/Users/frankfan/Desktop/Project/MJ 参考/ig_0c288488e46ec5530169ec2a39c1548191b49e351f2137cd4b.png")
BG_SOURCE = Path("/Users/frankfan/Desktop/Project/MJ 参考/ig_0c288488e46ec5530169ecb8fabd7881919b564301b43c8711.png")
OUT_DIR = ROOT / "assets" / "main_menu_layers"
OUT_DIR.mkdir(parents=True, exist_ok=True)


def to_canvas(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    width, height = image.size
    target_ratio = 16 / 9
    if width / height > target_ratio:
        new_width = int(height * target_ratio)
        x0 = (width - new_width) // 2
        image = image.crop((x0, 0, x0 + new_width, height))
    else:
        new_height = int(width / target_ratio)
        y0 = (height - new_height) // 2
        image = image.crop((0, y0, width, y0 + new_height))
    return image.resize((640, 360), Image.Resampling.LANCZOS)


def extract_layer(name: str, box: tuple[int, int, int, int], threshold: int = 28, dilate: int = 2, blur: float = 0.6) -> None:
    full_crop = full.crop(box)
    bg_crop = bg.crop(box)
    diff = ImageChops.difference(full_crop, bg_crop).convert("L")
    mask = diff.point(lambda value: 255 if value > threshold else 0)
    for _ in range(dilate):
        mask = mask.filter(ImageFilter.MaxFilter(3))
    if blur > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    result = full_crop.copy()
    result.putalpha(mask)
    result.save(OUT_DIR / f"{name}.png")
    layers[name] = {"x": box[0], "y": box[1], "w": box[2] - box[0], "h": box[3] - box[1]}


def extract_polygon_layer(name: str, box: tuple[int, int, int, int], polygon: list[tuple[int, int]], blur: float = 0.45) -> None:
    full_crop = full.crop(box)
    mask = Image.new("L", full_crop.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.polygon(polygon, fill=255)
    if blur > 0:
        mask = mask.filter(ImageFilter.GaussianBlur(blur))
    result = full_crop.copy()
    result.putalpha(mask)
    result.save(OUT_DIR / f"{name}.png")
    layers[name] = {"x": box[0], "y": box[1], "w": box[2] - box[0], "h": box[3] - box[1]}


full = to_canvas(FULL_SOURCE)
bg = to_canvas(BG_SOURCE)
bg.save(OUT_DIR / "background.png")

layers: dict[str, dict[str, int]] = {}

extract_layer("logo_sangoku_mahjong", (122, 10, 520, 158), threshold=22, dilate=2)
extract_layer("button_start_run", (218, 166, 422, 214), threshold=22, dilate=2)
extract_layer("button_collection", (218, 207, 422, 252), threshold=24, dilate=2)
extract_layer("button_options", (218, 245, 422, 290), threshold=24, dilate=2)
extract_layer("button_quit", (218, 282, 422, 327), threshold=24, dilate=2)
extract_layer("panel_highest_score", (6, 292, 156, 354), threshold=22, dilate=2)
extract_layer("panel_bonus_multiplier", (486, 292, 636, 354), threshold=22, dilate=2)
extract_layer("prototype_build", (242, 326, 398, 352), threshold=18, dilate=1)
extract_polygon_layer("tile_wan_left", (150, 218, 204, 304), [(8, 18), (39, 2), (53, 70), (22, 84), (2, 64)])
extract_polygon_layer("tile_fa_right", (424, 212, 474, 289), [(10, 18), (42, 4), (49, 62), (18, 76), (1, 59)])
extract_polygon_layer("tile_pin_right", (466, 206, 516, 286), [(7, 7), (44, 7), (49, 72), (7, 78), (0, 14)])
extract_polygon_layer("tile_dong_right", (506, 216, 564, 302), [(17, 4), (56, 17), (43, 83), (4, 72), (0, 16)])

with (OUT_DIR / "layers.lua").open("w", encoding="utf-8") as handle:
    handle.write("return {\n")
    handle.write('  background = "assets/main_menu_layers/background.png",\n')
    handle.write("  layers = {\n")
    for name, rect in layers.items():
        handle.write(
            f'    {{ name = "{name}", path = "assets/main_menu_layers/{name}.png", '
            f'x = {rect["x"]}, y = {rect["y"]}, w = {rect["w"]}, h = {rect["h"]} }},\n'
        )
    handle.write("  }\n")
    handle.write("}\n")

print(f"Wrote {OUT_DIR}")
