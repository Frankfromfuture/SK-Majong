#!/usr/bin/env -S godot -s
extends SceneTree

func _init():
    print("Loading FBX...")
    var fbx_path = "res://assets/models/mj/mjModelGroup.fbx"
    var packed_scene = load(fbx_path)
    if not packed_scene:
        print("Failed to load FBX. Godot might need to import it first. Please open Godot editor once.")
        quit(1)
        return
        
    var scene = packed_scene.instantiate()
    var output_dir = "res://assets/models/mj/tiles/"
    var dir = DirAccess.open("res://assets/models/mj/")
    if not dir.dir_exists("tiles"):
        dir.make_dir("tiles")
        
    print("Extracting meshes...")
    var count = 0
    
    # FBX files might have deeper hierarchies, let's use a recursive function
    _process_node(scene, output_dir)
    print("Done. Extraction script finished.")
    quit(0)

func _process_node(node: Node, output_dir: String):
    if node is MeshInstance3D:
        var mesh = node.mesh
        if mesh:
            # We want to extract single tiles. We assume each MeshInstance3D is a tile.
            # Clean up the name a bit
            var safe_name = node.name.replace(":", "_").replace(" ", "_")
            
            var new_scene = Node3D.new()
            new_scene.name = safe_name
            var new_mesh_inst = MeshInstance3D.new()
            new_mesh_inst.name = "Mesh"
            new_mesh_inst.mesh = mesh
            
            # Reset transform so it's centered
            new_mesh_inst.transform = Transform3D.IDENTITY
            
            new_scene.add_child(new_mesh_inst)
            new_mesh_inst.owner = new_scene
            var packed = PackedScene.new()
            packed.pack(new_scene)
            
            var tscn_path = output_dir + safe_name + ".tscn"
            ResourceSaver.save(packed, tscn_path)
            print("Saved scene: " + tscn_path)
            
    for child in node.get_children():
        _process_node(child, output_dir)
