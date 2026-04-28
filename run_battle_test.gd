#!/usr/bin/env -S godot -s
extends SceneTree

func _init():
    print("Loading battle scene...")
    var packed_scene = load("res://src/scenes/battle/battle.tscn")
    var scene = packed_scene.instantiate()
    root.add_child(scene)
    
    # Wait for a few frames to let process run
    for i in range(5):
        await root.get_tree().process_frame
        
    print("Exiting...")
    quit()
