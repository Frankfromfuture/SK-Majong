from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "generated"
OUT_DIR.mkdir(parents=True, exist_ok=True)

W, H = 512, 512
atlas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(atlas)

frames = {}


def rect_frame(name, x, y, w, h):
    frames[name] = {"x": x, "y": y, "w": w, "h": h}
    return ImageDraw.Draw(atlas.crop((x, y, x + w, y + h)))


def draw_panel(x, y, w, h, fill, border, accent=None, corners=True):
    d = draw
    d.rounded_rectangle((x + 3, y + 4, x + w - 2, y + h - 1), radius=5, fill=(0, 0, 0, 105))
    radius = 7 if corners else 1
    d.rounded_rectangle((x, y, x + w - 1, y + h - 1), radius=radius, fill=border)
    d.rounded_rectangle((x + 4, y + 4, x + w - 5, y + h - 5), radius=radius, fill=fill)
    d.rectangle((x + 8, y + 8, x + w - 9, y + 10), fill=accent or border)
    d.rectangle((x + 8, y + h - 11, x + w - 9, y + h - 9), fill=accent or border)
    for ox, oy in [(4, 4), (w - 13, 4), (4, h - 13), (w - 13, h - 13)]:
        d.rectangle((x + ox, y + oy, x + ox + 8, y + oy + 8), fill=accent or border)
        d.rectangle((x + ox + 3, y + oy + 3, x + ox + 5, y + oy + 5), fill=(255, 230, 126, 255))


def draw_tile(x, y, selected=False):
    name = "tile_selected" if selected else "tile_base"
    frames[name] = {"x": x, "y": y, "w": 64, "h": 88}
    edge = (255, 217, 96, 255) if selected else (118, 54, 29, 255)
    fill = (244, 219, 166, 255)
    draw.rounded_rectangle((x + 4, y + 5, x + 63, y + 87), radius=7, fill=(78, 31, 16, 255))
    draw.rounded_rectangle((x, y, x + 57, y + 81), radius=7, fill=edge)
    draw.rounded_rectangle((x + 5, y + 5, x + 52, y + 76), radius=5, fill=fill)
    draw.rectangle((x + 9, y + 9, x + 48, y + 11), fill=(255, 241, 190, 255))
    if selected:
        draw.rounded_rectangle((x - 1, y - 1, x + 58, y + 82), radius=8, outline=(255, 243, 116, 255), width=3)


def draw_chip(x, y):
    frames["coin_stack"] = {"x": x, "y": y, "w": 96, "h": 48}
    for cx, cy, r in [(22, 28, 16), (42, 20, 17), (62, 29, 15), (74, 18, 13)]:
        draw.ellipse((x + cx - r, y + cy - r, x + cx + r, y + cy + r), fill=(126, 72, 20, 255))
        draw.ellipse((x + cx - r + 3, y + cy - r + 3, x + cx + r - 3, y + cy + r - 3), fill=(229, 168, 47, 255))
        draw.rectangle((x + cx - 5, y + cy - 2, x + cx + 5, y + cy + 2), fill=(94, 50, 18, 255))


def draw_badge(x, y):
    frames["jade_badge"] = {"x": x, "y": y, "w": 48, "h": 48}
    draw.polygon([(x + 24, y), (x + 46, y + 12), (x + 46, y + 36), (x + 24, y + 48), (x + 2, y + 36), (x + 2, y + 12)], fill=(15, 113, 78, 255))
    draw.polygon([(x + 24, y + 5), (x + 40, y + 14), (x + 40, y + 34), (x + 24, y + 43), (x + 8, y + 34), (x + 8, y + 14)], fill=(25, 190, 118, 255))
    draw.ellipse((x + 17, y + 17, x + 31, y + 31), fill=(255, 210, 90, 255))


draw_panel(0, 0, 280, 56, (112, 21, 22, 255), (244, 164, 38, 255), (255, 220, 90, 255))
frames["button_red"] = {"x": 0, "y": 0, "w": 280, "h": 56}
draw_panel(0, 64, 280, 56, (10, 55, 42, 255), (185, 121, 32, 255), (255, 210, 88, 255))
frames["button_green"] = {"x": 0, "y": 64, "w": 280, "h": 56}
draw_panel(0, 128, 220, 64, (7, 44, 39, 245), (59, 143, 91, 255), (235, 177, 50, 255))
frames["panel_jade"] = {"x": 0, "y": 128, "w": 220, "h": 64}
draw_panel(0, 200, 180, 44, (12, 38, 34, 245), (170, 91, 30, 255), (255, 74, 45, 255))
frames["panel_small"] = {"x": 0, "y": 200, "w": 180, "h": 44}
draw_tile(304, 0, False)
draw_tile(376, 0, True)
draw_chip(304, 96)
draw_badge(416, 96)

draw.rounded_rectangle((304, 160, 488, 210), radius=6, fill=(41, 12, 18, 230), outline=(251, 173, 45, 255), width=4)
draw.rectangle((314, 170, 478, 174), fill=(255, 220, 86, 255))
frames["burst_plate"] = {"x": 304, "y": 160, "w": 184, "h": 52}

draw.rounded_rectangle((304, 232, 196 + 304, 84 + 232), radius=8, fill=(8, 18, 20, 210), outline=(251, 173, 45, 255), width=3)
frames["play_area"] = {"x": 304, "y": 232, "w": 196, "h": 84}

atlas.save(OUT_DIR / "ui_atlas.png")

with (OUT_DIR / "ui_atlas.lua").open("w", encoding="utf-8") as f:
    f.write("return { frames = {\n")
    for name in sorted(frames):
        r = frames[name]
        f.write(f"  {name} = {{ x = {r['x']}, y = {r['y']}, w = {r['w']}, h = {r['h']} }},\n")
    f.write("}}\n")

print(f"Wrote {OUT_DIR / 'ui_atlas.png'}")
print(f"Wrote {OUT_DIR / 'ui_atlas.lua'}")
