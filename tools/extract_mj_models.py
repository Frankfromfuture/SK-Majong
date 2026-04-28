import bpy
import sys
import os
import math

argv = sys.argv
argv = argv[argv.index("--") + 1:] # get all args after "--"

fbx_path = argv[0]
output_dir = argv[1]

# Clear existing objects
bpy.ops.wm.read_factory_settings(use_empty=True)

# Import FBX
bpy.ops.import_scene.fbx(filepath=fbx_path)

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

# List of all objects
all_objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']

# We are only interested in the meshes that actually represent individual tiles
# The FBX might contain groups or other parts, but let's assume all meshes are tiles
for obj in all_objects:
    # Select only this object
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    
    # Reset position to center, and apply rotation/scale if needed
    obj.location = (0, 0, 0)
    
    # Export as OBJ or glTF (GLTF is usually better for Godot)
    export_path = os.path.join(output_dir, f"{obj.name}.gltf")
    bpy.ops.export_scene.gltf(filepath=export_path, use_selection=True, export_format='GLTF_SEPARATE')
    
    print(f"Exported {export_path}")

print("Done exporting all meshes.")
