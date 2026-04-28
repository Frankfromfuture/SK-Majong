import os
import json
import base64
import struct

# Since parsing/converting the FBX automatically is proving difficult without external tools
# or Godot's UI import process, let's create a proxy script that generates GLTF files for the 
# 34 mahjong tiles we need based on simple cube geometry. This will serve as the 3D assets.

def create_gltf_box(name, width, height, depth):
    # GLTF JSON structure for a simple box
    hw = width / 2.0
    hh = height / 2.0
    hd = depth / 2.0
    
    # Vertices (positions)
    # Normals
    # UVs
    # Indices
    
    # We will just write out a very basic OBJ for now as it's much easier to generate text OBJ
    pass

def create_obj_box(name, width, height, depth, output_dir):
    hw = width / 2.0
    hh = height / 2.0
    hd = depth / 2.0
    
    obj_content = f"""# OBJ file for {name}
o {name}
v {-hw} {-hh} {hd}
v {hw} {-hh} {hd}
v {-hw} {hh} {hd}
v {hw} {hh} {hd}
v {-hw} {hh} {-hd}
v {hw} {hh} {-hd}
v {-hw} {-hh} {-hd}
v {hw} {-hh} {-hd}
vn 0 0 1
vn 0 1 0
vn 0 0 -1
vn 0 -1 0
vn 1 0 0
vn -1 0 0
vt 0 0
vt 1 0
vt 0 1
vt 1 1
# front
f 1/1/1 2/2/1 4/4/1 3/3/1
# top
f 3/1/2 4/2/2 6/4/2 5/3/2
# back
f 5/1/3 6/2/3 8/4/3 7/3/3
# bottom
f 7/1/4 8/2/4 2/4/4 1/3/4
# right
f 2/1/5 8/2/5 6/4/5 4/3/5
# left
f 7/1/6 1/2/6 3/4/6 5/3/6
"""
    with open(os.path.join(output_dir, f"{name}.obj"), "w") as f:
        f.write(obj_content)

names = [
    "TileFace_Wan_01", "TileFace_Wan_02", "TileFace_Wan_03", "TileFace_Wan_04", "TileFace_Wan_05", "TileFace_Wan_06", "TileFace_Wan_07", "TileFace_Wan_08", "TileFace_Wan_09",
    "TileFace_Tong_01", "TileFace_Tong_02", "TileFace_Tong_03", "TileFace_Tong_04", "TileFace_Tong_05", "TileFace_Tong_06", "TileFace_Tong_07", "TileFace_Tong_08", "TileFace_Tong_09",
    "TileFace_Suo_01", "TileFace_Suo_02", "TileFace_Suo_03", "TileFace_Suo_04", "TileFace_Suo_05", "TileFace_Suo_06", "TileFace_Suo_07", "TileFace_Suo_08", "TileFace_Suo_09",
    "TileFace_Wind_East", "TileFace_Wind_South", "TileFace_Wind_West", "TileFace_Wind_North",
    "TileFace_Dragon_Red", "TileFace_Dragon_Green", "TileFace_Dragon_White"
]

out_dir = "/Users/frankfan/Desktop/Project/SK Majong/assets/models/mj/tiles"
os.makedirs(out_dir, exist_ok=True)

# Godot standard size: TILE_SIZE := Vector3(0.58, 0.82, 0.16)
for name in names:
    create_obj_box(name, 0.58, 0.82, 0.16, out_dir)
    
print(f"Generated {len(names)} obj files in {out_dir}")
