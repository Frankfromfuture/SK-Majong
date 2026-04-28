class_name MahjongTile3D
extends Node3D

const TILE_SIZE := Vector3(0.58, 0.82, 0.10)
const FACE_SIZE := Vector2(0.48, 0.70)
const BEVEL_WIDTH := 0.026
const CORNER_TRIM_SIZE := 0.048
const CORNER_RADIUS := 0.052
const CORNER_SEGMENTS := 1
const FRONT_Z := TILE_SIZE.z * 0.5
const BACK_Z := -TILE_SIZE.z * 0.5
const FRONT_BEVEL_Z := TILE_SIZE.z * 0.34
const BACK_BEVEL_Z := -TILE_SIZE.z * 0.34
const NORMAL_TEXTURE_PATH := "res://assets/models/mj/mj_normal.png"

## Path pattern for individual tile face textures.
## Expected: res://assets/sprites/battle/Textures/TileFace_<suit>_<rank>.png
const FACE_TEXTURE_DIR := "res://assets/sprites/battle/Textures/"

var tile: Tile
var phase := 0.0
var base_position := Vector3.ZERO
var selected := false
var hovered := false
var _glow_node: MeshInstance3D
var _shine_node: MeshInstance3D


func setup(p_tile: Tile, p_selected := false, p_phase := 0.0, p_hovered := false) -> void:
	tile = p_tile
	selected = p_selected
	phase = p_phase
	hovered = p_hovered
	name = "MahjongTile3D_%s_%02d" % [_suit_key(), tile.rank]
	_build_mesh()


func set_hovered(p_hovered: bool) -> void:
	if hovered == p_hovered:
		return
	hovered = p_hovered
	_build_mesh()


func _process(delta: float) -> void:
	phase += delta
	var interaction_lift := 0.0
	if selected:
		interaction_lift = 0.070
	elif hovered:
		interaction_lift = 0.046
	position = base_position + Vector3(0.0, interaction_lift, 0.0)
	rotation_degrees.y = 0.0

	# Animate selection glow
	if _glow_node != null:
		var pulse := (sin(phase * 4.2) + 1.0) * 0.5
		var mat: StandardMaterial3D = _glow_node.material_override
		if mat != null:
			mat.albedo_color.a = lerp(0.18, 0.52, pulse)
			mat.emission_energy_multiplier = lerp(0.08, 0.38, pulse)

	# Animate shine sweep
	if _shine_node != null:
		_shine_node.position.y = 0.26


func _build_mesh() -> void:
	for child in get_children():
		child.queue_free()
	_glow_node = null
	_shine_node = null

	_build_pixel_drop_shadow()
	_build_body()
	_build_edge_band()
	_build_back_plate()
	_build_face_plate()
	_build_face_content()
	_build_corner_trims()
	_build_shine()

	if selected or hovered:
		_build_interaction_glow()


# --- Body -------------------------------------------------------------------

func _build_body() -> void:
	var body := MeshInstance3D.new()
	body.name = "TileBodyMesh"
	body.mesh = _build_cap_mesh(_rounded_rect_points(
		Vector2(TILE_SIZE.x * 0.5 - BEVEL_WIDTH, TILE_SIZE.y * 0.5 - BEVEL_WIDTH),
		max(CORNER_RADIUS - BEVEL_WIDTH, 0.01),
		CORNER_SEGMENTS
	), FRONT_Z)
	body.material_override = _ivory_body_material()
	add_child(body)


func _build_pixel_drop_shadow() -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "TilePixelDropShadow"
	var quad := QuadMesh.new()
	quad.size = Vector2(TILE_SIZE.x + 0.055, TILE_SIZE.y + 0.055)
	shadow.mesh = quad
	shadow.position = Vector3(0.030, -0.038, BACK_Z - 0.006)
	shadow.material_override = _flat_alpha_material(Color(0.0, 0.0, 0.0, 0.26))
	add_child(shadow)


# --- Rounded side, bevel, and back surfaces ----------------------------------

func _build_edge_band() -> void:
	var edge := MeshInstance3D.new()
	edge.name = "TileCopperEdgeMesh"
	var outer_points := _rounded_rect_points(
		Vector2(TILE_SIZE.x * 0.5, TILE_SIZE.y * 0.5),
		CORNER_RADIUS,
		CORNER_SEGMENTS
	)
	var front_points := _rounded_rect_points(
		Vector2(TILE_SIZE.x * 0.5 - BEVEL_WIDTH, TILE_SIZE.y * 0.5 - BEVEL_WIDTH),
		max(CORNER_RADIUS - BEVEL_WIDTH, 0.01),
		CORNER_SEGMENTS
	)
	var back_points := _rounded_rect_points(
		Vector2(TILE_SIZE.x * 0.5 - BEVEL_WIDTH * 0.7, TILE_SIZE.y * 0.5 - BEVEL_WIDTH * 0.7),
		max(CORNER_RADIUS - BEVEL_WIDTH * 0.7, 0.01),
		CORNER_SEGMENTS
	)
	edge.mesh = _build_band_mesh([
		{"points": front_points, "z": FRONT_Z},
		{"points": outer_points, "z": FRONT_BEVEL_Z},
		{"points": outer_points, "z": BACK_BEVEL_Z},
		{"points": back_points, "z": BACK_Z},
	])
	edge.material_override = _bevel_material()
	add_child(edge)


func _build_back_plate() -> void:
	var back := MeshInstance3D.new()
	back.name = "TileBackInlayMesh"
	back.mesh = _build_cap_mesh(_rounded_rect_points(
		Vector2(TILE_SIZE.x * 0.5 - BEVEL_WIDTH * 1.35, TILE_SIZE.y * 0.5 - BEVEL_WIDTH * 1.35),
		max(CORNER_RADIUS - BEVEL_WIDTH * 1.35, 0.01),
		CORNER_SEGMENTS
	), BACK_Z - 0.001, true)
	back.material_override = _back_material()
	add_child(back)


func _rounded_rect_points(half_size: Vector2, radius: float, segments: int) -> Array:
	if segments <= 1:
		return [
			Vector2(half_size.x, half_size.y - radius),
			Vector2(half_size.x - radius, half_size.y),
			Vector2(-half_size.x + radius, half_size.y),
			Vector2(-half_size.x, half_size.y - radius),
			Vector2(-half_size.x, -half_size.y + radius),
			Vector2(-half_size.x + radius, -half_size.y),
			Vector2(half_size.x - radius, -half_size.y),
			Vector2(half_size.x, -half_size.y + radius),
		]
	var points := []
	var centers := [
		Vector2(half_size.x - radius, half_size.y - radius),
		Vector2(-half_size.x + radius, half_size.y - radius),
		Vector2(-half_size.x + radius, -half_size.y + radius),
		Vector2(half_size.x - radius, -half_size.y + radius),
	]
	var angle_ranges := [
		Vector2(0.0, 90.0),
		Vector2(90.0, 180.0),
		Vector2(180.0, 270.0),
		Vector2(270.0, 360.0),
	]
	for corner_index in range(centers.size()):
		for step in range(segments + 1):
			if corner_index > 0 and step == 0:
				continue
			var t := float(step) / float(max(segments, 1))
			var angle_range: Vector2 = angle_ranges[corner_index]
			var corner_center: Vector2 = centers[corner_index]
			var degrees: float = lerp(angle_range.x, angle_range.y, t)
			var radians: float = deg_to_rad(degrees)
			points.append(corner_center + Vector2(cos(radians), sin(radians)) * radius)
	return points


func _build_cap_mesh(points: Array, z: float, flip := false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(0.0, 0.0, z)
	for i in range(points.size()):
		var current: Vector2 = points[i]
		var next: Vector2 = points[(i + 1) % points.size()]
		if flip:
			_add_vertex(st, center)
			_add_vertex(st, Vector3(next.x, next.y, z))
			_add_vertex(st, Vector3(current.x, current.y, z))
		else:
			_add_vertex(st, center)
			_add_vertex(st, Vector3(current.x, current.y, z))
			_add_vertex(st, Vector3(next.x, next.y, z))
	st.generate_normals()
	return st.commit()


func _build_band_mesh(layers: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for layer_index in range(layers.size() - 1):
		var current_points: Array = layers[layer_index]["points"]
		var next_points: Array = layers[layer_index + 1]["points"]
		var current_z: float = layers[layer_index]["z"]
		var next_z: float = layers[layer_index + 1]["z"]
		for i in range(current_points.size()):
			var current: Vector2 = current_points[i]
			var current_next: Vector2 = current_points[(i + 1) % current_points.size()]
			var next: Vector2 = next_points[i]
			var next_next: Vector2 = next_points[(i + 1) % next_points.size()]
			var a := Vector3(current.x, current.y, current_z)
			var b := Vector3(current_next.x, current_next.y, current_z)
			var c := Vector3(next.x, next.y, next_z)
			var d := Vector3(next_next.x, next_next.y, next_z)
			_add_vertex(st, a)
			_add_vertex(st, b)
			_add_vertex(st, d)
			_add_vertex(st, a)
			_add_vertex(st, d)
			_add_vertex(st, c)
	st.generate_normals()
	return st.commit()


func _add_vertex(st: SurfaceTool, vertex: Vector3) -> void:
	st.set_uv(Vector2(
		(vertex.x / TILE_SIZE.x) + 0.5,
		1.0 - ((vertex.y / TILE_SIZE.y) + 0.5)
	))
	st.add_vertex(vertex)


# --- Legacy bevel strips (unused by default) ---------------------------------

func _build_bevel_edges() -> void:
	var half_w := TILE_SIZE.x * 0.5
	var half_h := TILE_SIZE.y * 0.5
	var z_front := TILE_SIZE.z * 0.5 + 0.001

	# Top bevel
	_add_bevel_strip("BevelTop",
		Vector3(0.0, half_h - BEVEL_WIDTH * 0.5, z_front),
		Vector2(TILE_SIZE.x, BEVEL_WIDTH))

	# Bottom bevel
	_add_bevel_strip("BevelBottom",
		Vector3(0.0, -half_h + BEVEL_WIDTH * 0.5, z_front),
		Vector2(TILE_SIZE.x, BEVEL_WIDTH))

	# Left bevel
	_add_bevel_strip("BevelLeft",
		Vector3(-half_w + BEVEL_WIDTH * 0.5, 0.0, z_front),
		Vector2(BEVEL_WIDTH, TILE_SIZE.y))

	# Right bevel
	_add_bevel_strip("BevelRight",
		Vector3(half_w - BEVEL_WIDTH * 0.5, 0.0, z_front),
		Vector2(BEVEL_WIDTH, TILE_SIZE.y))


func _add_bevel_strip(strip_name: String, pos: Vector3, size: Vector2) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = strip_name
	var quad := QuadMesh.new()
	quad.size = size
	mesh_inst.mesh = quad
	mesh_inst.position = pos
	mesh_inst.material_override = _bevel_material()
	add_child(mesh_inst)


# --- Face plate (ivory panel beneath content) --------------------------------

func _build_face_plate() -> void:
	var face := MeshInstance3D.new()
	face.name = "TileFacePlate"
	var quad := QuadMesh.new()
	quad.size = FACE_SIZE
	face.mesh = quad
	face.position = Vector3(0.0, 0.0, FRONT_Z + 0.004)
	face.material_override = _face_plate_material()
	add_child(face)

	_add_pixel_strip("TileFaceBorderTop", Vector3(0.0, FACE_SIZE.y * 0.5 + 0.007, FRONT_Z + 0.010), Vector2(FACE_SIZE.x + 0.028, 0.016), _pixel_border_material())
	_add_pixel_strip("TileFaceBorderBottom", Vector3(0.0, -FACE_SIZE.y * 0.5 - 0.007, FRONT_Z + 0.010), Vector2(FACE_SIZE.x + 0.028, 0.016), _pixel_border_material())
	_add_pixel_strip("TileFaceBorderLeft", Vector3(-FACE_SIZE.x * 0.5 - 0.007, 0.0, FRONT_Z + 0.010), Vector2(0.016, FACE_SIZE.y + 0.028), _pixel_border_material())
	_add_pixel_strip("TileFaceBorderRight", Vector3(FACE_SIZE.x * 0.5 + 0.007, 0.0, FRONT_Z + 0.010), Vector2(0.016, FACE_SIZE.y + 0.028), _pixel_border_material())


func _add_pixel_strip(strip_name: String, pos: Vector3, size: Vector2, mat: StandardMaterial3D) -> void:
	var strip := MeshInstance3D.new()
	strip.name = strip_name
	var quad := QuadMesh.new()
	quad.size = size
	strip.mesh = quad
	strip.position = pos
	strip.material_override = mat
	add_child(strip)


# --- Face content (texture or Label3D fallback) ------------------------------

func _build_face_content() -> void:
	var texture := _load_face_texture(_face_texture_path())
	if texture == null:
		_build_face_label()
	else:
		_build_face_sprite(texture)


func _build_face_sprite(texture: Texture2D) -> void:
	var face_mesh := MeshInstance3D.new()
	face_mesh.name = "TileFaceSprite"
	var quad := QuadMesh.new()
	quad.size = FACE_SIZE * 0.86
	face_mesh.mesh = quad
	face_mesh.position = Vector3(0.0, 0.0, FRONT_Z + 0.011)
	face_mesh.material_override = _face_texture_material(texture)
	add_child(face_mesh)


func _load_face_texture(texture_path: String) -> Texture2D:
	var absolute_path := ProjectSettings.globalize_path(texture_path)
	if not FileAccess.file_exists(absolute_path):
		return null
	var image: Image = Image.load_from_file(absolute_path)
	if image == null or image.is_empty():
		return null
	image.fix_alpha_edges()
	return ImageTexture.create_from_image(image)


func _build_face_label() -> void:
	var mark := Label3D.new()
	mark.name = "TileFaceLabel"
	mark.text = _face_text()
	mark.font_size = 68 if tile.is_suited() else 82
	mark.pixel_size = 0.0048
	mark.outline_size = 5
	mark.outline_modulate = Color(0.0, 0.0, 0.0, 0.40)
	mark.modulate = _face_color()
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.position = Vector3(0.0, 0.0, FRONT_Z + 0.012)
	add_child(mark)


# --- Corner trims (ornate copper/gold corner decoration) ---------------------

func _build_corner_trims() -> void:
	var hw := FACE_SIZE.x * 0.5 - 0.01
	var hh := FACE_SIZE.y * 0.5 - 0.01
	var z := FRONT_Z + 0.014

	var corners := [
		Vector3(-hw, hh, z),
		Vector3(hw, hh, z),
		Vector3(-hw, -hh, z),
		Vector3(hw, -hh, z),
	]

	for i in range(corners.size()):
		var corner := MeshInstance3D.new()
		corner.name = "CornerTrim_%02d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(CORNER_TRIM_SIZE, CORNER_TRIM_SIZE)
		corner.mesh = quad
		corner.position = corners[i]
		corner.material_override = _corner_trim_material()
		add_child(corner)


# --- Shine (reflective strip across top) -------------------------------------

func _build_shine() -> void:
	_shine_node = MeshInstance3D.new()
	_shine_node.name = "TilePixelHighlight"
	var shine_quad := QuadMesh.new()
	shine_quad.size = Vector2(0.34, 0.018)
	_shine_node.mesh = shine_quad
	_shine_node.position = Vector3(-0.030, 0.260, FRONT_Z + 0.018)
	_shine_node.material_override = _shine_material()
	add_child(_shine_node)


# --- Interaction glow --------------------------------------------------------

func _build_interaction_glow() -> void:
	_glow_node = MeshInstance3D.new()
	_glow_node.name = "TileSelectedGlow" if selected else "TileHoverGlow"
	var glow_quad := QuadMesh.new()
	glow_quad.size = Vector2(0.66, 0.90)
	_glow_node.mesh = glow_quad
	_glow_node.position = Vector3(0.0, 0.0, FRONT_Z + 0.001)
	_glow_node.material_override = _glow_material(Color(1.0, 0.48, 0.12), Color(1.0, 0.72, 0.18)) if selected else _glow_material(Color(0.60, 1.0, 0.82), Color(0.28, 1.0, 0.68))
	add_child(_glow_node)


# === Material factories =====================================================

func _ivory_body_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.90, 0.82, 0.58)
	mat.roughness = 0.82
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.90, 0.72, 0.38)
	mat.emission_energy_multiplier = 0.08
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _face_plate_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.92, 0.66)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.82, 0.44)
	mat.emission_energy_multiplier = 0.10
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _face_texture_material(texture: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.albedo_texture = texture
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


func _bevel_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.52, 0.34)
	mat.roughness = 0.88
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.06, 0.20, 0.10)
	mat.emission_energy_multiplier = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _back_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.28, 0.18)
	mat.roughness = 0.86
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.02, 0.12, 0.06)
	mat.emission_energy_multiplier = 0.05
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _corner_trim_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.46, 0.30, 0.92)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.06, 0.18, 0.08)
	mat.emission_energy_multiplier = 0.07
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _shine_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.78, 0.40)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.82, 0.30)
	mat.emission_energy_multiplier = 0.10
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _glow_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(albedo.r, albedo.g, albedo.b, 0.38)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = 0.16
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _pixel_border_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.23, 0.38, 0.24)
	mat.roughness = 0.90
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.05, 0.12, 0.04)
	mat.emission_energy_multiplier = 0.06
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _flat_alpha_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	return mat


func _apply_normal_texture(mat: StandardMaterial3D, scale: float) -> void:
	var normal_texture := load(NORMAL_TEXTURE_PATH) as Texture2D
	if normal_texture == null:
		return
	mat.normal_enabled = true
	mat.normal_texture = normal_texture
	mat.normal_scale = scale


# === Face helpers ============================================================

func _face_text() -> String:
	if tile.is_suited():
		return "%d\n%s" % [tile.rank, Tile.SUIT_NAMES[tile.suit]]
	return tile.display_name()


func _face_color() -> Color:
	match tile.suit:
		Tile.Suit.MAN:
			return Color(0.92, 0.12, 0.08)
		Tile.Suit.PIN:
			return Color(0.05, 0.12, 0.13)
		Tile.Suit.SOU:
			return Color(0.02, 0.55, 0.22)
		Tile.Suit.WIND:
			return Color(0.04, 0.13, 0.12)
		Tile.Suit.DRAGON:
			if tile.rank == 1:
				return Color(0.92, 0.10, 0.08)
			if tile.rank == 2:
				return Color(0.02, 0.55, 0.22)
			return Color(0.10, 0.10, 0.10)
	return Color.BLACK


func _suit_key() -> String:
	match tile.suit:
		Tile.Suit.MAN:
			return "Wan"
		Tile.Suit.PIN:
			return "Tong"
		Tile.Suit.SOU:
			return "Suo"
		Tile.Suit.WIND:
			return "Wind"
		Tile.Suit.DRAGON:
			return "Dragon"
	return "Unknown"


func _face_texture_path() -> String:
	var suit_key := _suit_key()
	var rank_str := "%02d" % tile.rank
	if tile.suit == Tile.Suit.WIND:
		var wind_map := {1: "East", 2: "South", 3: "West", 4: "North"}
		rank_str = wind_map.get(tile.rank, rank_str)
	elif tile.suit == Tile.Suit.DRAGON:
		var dragon_map := {1: "Red", 2: "Green", 3: "White"}
		rank_str = dragon_map.get(tile.rank, rank_str)
	return FACE_TEXTURE_DIR + "TileFace_%s_%s.png" % [suit_key, rank_str]
