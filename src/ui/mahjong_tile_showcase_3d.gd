class_name MahjongTileShowcase3D
extends SubViewportContainer

const MahjongTile3DScript = preload("res://src/ui/mahjong_tile_3d.gd")
const TILE_HIT_HALF_WIDTH := 0.36
const TILE_HIT_HALF_HEIGHT := 0.48

signal tile_hovered(zone: int, index: int, is_hovered: bool)
signal tile_pressed(zone: int, index: int)

var viewport: SubViewport
var scene_root: Node3D
var tile_root: Node3D
var camera: Camera3D
var selected_keys := {}
var hovered_keys := {}
var current_zone := -1
var tile_count := 0
var hovered_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_exited.connect(_clear_hover)


func setup_tiles(tiles: Array, p_selected_keys := {}, p_hovered_keys := {}, zone := -1) -> void:
	selected_keys = p_selected_keys
	hovered_keys = p_hovered_keys
	current_zone = zone
	tile_count = tiles.size()
	_ensure_viewport()
	_clear_tiles()

	var count: int = max(tiles.size(), 1)
	var spacing := 0.44 if count > 4 else 0.56
	var arc_width := float(count - 1) * spacing
	for i in range(tiles.size()):
		var tile: Tile = tiles[i]
		var tile_3d: Node3D = MahjongTile3DScript.new() as Node3D
		var key := "%d:%d" % [zone, i]
		tile_3d.call("setup", tile, selected_keys.has(key), float(i) * 0.37, hovered_keys.has(key))
		tile_3d.name = "MahjongTile3D_%02d" % i
		var base_position := Vector3(float(i) * spacing - arc_width * 0.5, _arc_y(i, count), 0.0)
		tile_3d.set("base_position", base_position)
		tile_3d.position = base_position
		tile_3d.rotation_degrees.x = -9.0
		tile_3d.rotation_degrees.z = (float(i) - float(count - 1) * 0.5) * 1.4
		tile_root.add_child(tile_3d)

	camera.size = 1.35 if count > 4 else 1.15


func set_tile_hovered(zone: int, index: int, is_hovered: bool) -> void:
	var key := "%d:%d" % [zone, index]
	if is_hovered:
		hovered_keys[key] = true
	else:
		hovered_keys.erase(key)
	if zone != current_zone or tile_root == null:
		return
	var tile_3d := tile_root.get_node_or_null("MahjongTile3D_%02d" % index)
	if tile_3d != null:
		tile_3d.call("set_hovered", is_hovered)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index := _index_from_position(event.position)
		if index >= 0:
			tile_pressed.emit(current_zone, index)
			accept_event()


func _update_hover_from_position(local_position: Vector2) -> void:
	var index := _index_from_position(local_position)
	if index == hovered_index:
		return
	if hovered_index >= 0:
		tile_hovered.emit(current_zone, hovered_index, false)
	hovered_index = index
	if hovered_index >= 0:
		tile_hovered.emit(current_zone, hovered_index, true)


func _index_from_position(local_position: Vector2) -> int:
	if tile_count <= 0:
		return -1
	if local_position.x < 0.0 or local_position.y < 0.0 or local_position.x > size.x or local_position.y > size.y:
		return -1

	var best_index := -1
	var best_distance := INF
	for i in range(tile_count):
		var hit_rect := _tile_hit_rect(i)
		if hit_rect.has_point(local_position):
			var distance := local_position.distance_squared_to(hit_rect.get_center())
			if distance < best_distance:
				best_distance = distance
				best_index = i
	return best_index


func _tile_hit_rect(index: int) -> Rect2:
	if camera == null or viewport == null or tile_root == null:
		return Rect2()
	var tile_3d := tile_root.get_node_or_null("MahjongTile3D_%02d" % index) as Node3D
	if tile_3d == null:
		return Rect2()

	var viewport_to_local := Vector2(
		size.x / max(float(viewport.size.x), 1.0),
		size.y / max(float(viewport.size.y), 1.0)
	)
	var corners := [
		Vector3(-TILE_HIT_HALF_WIDTH, -TILE_HIT_HALF_HEIGHT, 0.0),
		Vector3(TILE_HIT_HALF_WIDTH, -TILE_HIT_HALF_HEIGHT, 0.0),
		Vector3(-TILE_HIT_HALF_WIDTH, TILE_HIT_HALF_HEIGHT, 0.0),
		Vector3(TILE_HIT_HALF_WIDTH, TILE_HIT_HALF_HEIGHT, 0.0),
	]
	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	for corner in corners:
		var viewport_pos := camera.unproject_position(tile_3d.global_transform * corner)
		var local_pos := viewport_pos * viewport_to_local
		min_pos.x = min(min_pos.x, local_pos.x)
		min_pos.y = min(min_pos.y, local_pos.y)
		max_pos.x = max(max_pos.x, local_pos.x)
		max_pos.y = max(max_pos.y, local_pos.y)
	return Rect2(min_pos, max_pos - min_pos).grow(8.0)


func _clear_hover() -> void:
	if hovered_index >= 0:
		tile_hovered.emit(current_zone, hovered_index, false)
	hovered_index = -1


func _ensure_viewport() -> void:
	if viewport != null:
		return

	stretch = true
	stretch_shrink = 1
	viewport = SubViewport.new()
	viewport.name = "Tile3DViewport"
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = _high_quality_viewport_size()
	add_child(viewport)

	scene_root = Node3D.new()
	scene_root.name = "Tile3DSceneRoot"
	viewport.add_child(scene_root)

	var world := WorldEnvironment.new()
	world.name = "Tile3DWorldEnvironment"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.78, 0.72)
	environment.ambient_light_energy = 1.35
	# Tonemap and glow can break transparent backgrounds in Godot 4 SubViewports
	# environment.tonemap_mode = Environment.TONE_MAP_ACES
	# environment.glow_enabled = true
	world.environment = environment
	scene_root.add_child(world)

	# Key light — warm directional from top-left
	var key_light := DirectionalLight3D.new()
	key_light.name = "Tile3DKeyLight"
	key_light.light_energy = 2.25
	key_light.light_color = Color(1.0, 0.93, 0.82)
	key_light.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	key_light.shadow_enabled = true
	scene_root.add_child(key_light)

	# Fill light — cool omni from front-right
	var fill_light := OmniLight3D.new()
	fill_light.name = "Tile3DFillLight"
	fill_light.light_energy = 0.54
	fill_light.light_color = Color(0.82, 0.88, 1.0)
	fill_light.omni_range = 6.0
	fill_light.position = Vector3(1.8, 0.8, 3.2)
	scene_root.add_child(fill_light)

	# Rim light — subtle accent from below
	var rim_light := OmniLight3D.new()
	rim_light.name = "Tile3DRimLight"
	rim_light.light_energy = 0.62
	rim_light.light_color = Color(1.0, 0.74, 0.40)
	rim_light.omni_range = 4.0
	rim_light.position = Vector3(-1.2, -1.1, 1.8)
	scene_root.add_child(rim_light)

	camera = Camera3D.new()
	camera.name = "Tile3DCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.35
	camera.position = Vector3(0.0, 0.0, 5.2)
	camera.current = true
	scene_root.add_child(camera)
	camera.look_at(Vector3.ZERO, Vector3.UP)

	tile_root = Node3D.new()
	tile_root.name = "Tile3DRoot"
	scene_root.add_child(tile_root)


func _high_quality_viewport_size() -> Vector2i:
	var render_scale := 4.0
	return Vector2i(max(1024, int(size.x * render_scale)), max(256, int(size.y * render_scale)))


func _clear_tiles() -> void:
	for child in tile_root.get_children():
		child.queue_free()


func _arc_y(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	var centered := (float(index) / float(count - 1)) * 2.0 - 1.0
	return -abs(centered) * 0.08
