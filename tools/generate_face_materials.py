import os

names = [
    "TileFace_Wan_01", "TileFace_Wan_02", "TileFace_Wan_03", "TileFace_Wan_04", "TileFace_Wan_05", "TileFace_Wan_06", "TileFace_Wan_07", "TileFace_Wan_08", "TileFace_Wan_09",
    "TileFace_Tong_01", "TileFace_Tong_02", "TileFace_Tong_03", "TileFace_Tong_04", "TileFace_Tong_05", "TileFace_Tong_06", "TileFace_Tong_07", "TileFace_Tong_08", "TileFace_Tong_09",
    "TileFace_Suo_01", "TileFace_Suo_02", "TileFace_Suo_03", "TileFace_Suo_04", "TileFace_Suo_05", "TileFace_Suo_06", "TileFace_Suo_07", "TileFace_Suo_08", "TileFace_Suo_09",
    "TileFace_Wind_East", "TileFace_Wind_South", "TileFace_Wind_West", "TileFace_Wind_North",
    "TileFace_Dragon_Red", "TileFace_Dragon_Green", "TileFace_Dragon_White"
]

out_dir = "/Users/frankfan/Desktop/Project/SK Majong/assets/models/mj/tiles"
os.makedirs(out_dir, exist_ok=True)

for name in names:
    tres_content = f"""[gd_resource type="StandardMaterial3D" load_steps=2 format=3 uid="uid://testuid12345"]

[ext_resource type="Texture2D" uid="uid://testuidtex" path="res://assets/sprites/battle/Textures/{name}.png" id="1_tex"]

[resource]
albedo_texture = ExtResource("1_tex")
roughness = 0.2
"""
    with open(os.path.join(out_dir, f"{name}.tres"), "w") as f:
        f.write(tres_content)
print(f"Generated 34 materials in {out_dir}")
