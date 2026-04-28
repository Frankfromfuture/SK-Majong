extends Control

const LayeredBackgroundScript = preload("res://src/ui/layered_background.gd")
const BG_TEXTURE: Texture2D = preload("res://assets/sprites/main_menu/bg_main_menu.png")
const ASSET_SHEET: Texture2D = preload("res://assets/sprites/main_menu/main_menu_asset_sheet.png")

const RECT_RED_BUTTON := Rect2(16, 88, 346, 164)
const RECT_GREEN_BUTTON := Rect2(362, 82, 362, 156)
const RECT_SCORE_PANEL := Rect2(724, 94, 358, 154)
const RECT_BONUS_PANEL := Rect2(1116, 104, 296, 144)
const RECT_JADE_DRAGON := Rect2(66, 366, 292, 332)
const RECT_LANTERN := Rect2(468, 362, 154, 352)
const RECT_COINS := Rect2(724, 392, 348, 272)
const RECT_TILE_BASE := Rect2(1168, 380, 178, 258)
const RECT_BANNER_LEFT := Rect2(78, 724, 214, 292)
const RECT_BANNER_RIGHT := Rect2(438, 724, 214, 292)
const RECT_TOP_BANNER := Rect2(652, 728, 400, 250)
const RECT_TILE_CLUSTER := Rect2(1086, 766, 322, 202)
const UI_ASSET_SCALE := 0.24

var _time := 0.0
var main_title: Label
var subtitle_label: Label
var _animated_nodes: Array[Dictionary] = []


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_wire_existing_menu()


func _process(delta: float) -> void:
	_time += delta
	if main_title != null:
		main_title.position.y = 30.0 + sin(_time * 1.5) * 2.0
		main_title.scale = Vector2.ONE * (1.0 + sin(_time * 2.1) * 0.015)
	if subtitle_label != null:
		subtitle_label.modulate.a = 0.58 + sin(_time * 3.1) * 0.20
	for i in range(_animated_nodes.size()):
		var data := _animated_nodes[i]
		var node: Control = data["node"]
		var base_position: Vector2 = data["base"]
		var float_amount: float = data["float"]
		var speed: float = data["speed"]
		node.position = base_position + Vector2(0.0, sin(_time * speed + i * 0.8) * float_amount)
		node.rotation_degrees = data["rotation"] + sin(_time * (speed * 0.7) + i) * data["wobble"]


func _wire_existing_menu() -> void:
	main_title = find_child("MainTitle", true, false) as Label
	subtitle_label = find_child("MainSubtitle", true, false) as Label
	_animated_nodes.clear()
	_track_animation("LeftBannerSprite", 1.5, 0.8, 1.4)
	_track_animation("RightBannerSprite", 1.5, 0.85, 1.4)
	_track_animation("JadeStatueLeftSprite", 2.2, 0.9, 1.2)
	_track_animation("LanternRightSprite", 3.0, 1.1, 1.8)
	_track_animation("CoinStacksLeftSprite", 2.0, 1.0, 1.2)
	_track_animation("CoinStacksRightSprite", 2.0, 1.05, 1.2)
	_track_animation("MenuTileClusterSprite", 2.4, 0.95, 1.3)
	_track_animation("LogoSprite", 1.8, 0.75, 0.6)
	_track_animation("MenuTile_Wan_01", 2.2, 1.0, 1.4)
	_track_animation("MenuTile_Fa_01", 2.2, 1.0, 1.4)
	_track_animation("MenuTile_Dong_01", 2.2, 1.0, 1.4)

	var start_button := find_child("StartRunButton", true, false) as Button
	if start_button != null:
		start_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
		)
	var quit_button := find_child("QuitButton", true, false) as Button
	if quit_button != null:
		quit_button.pressed.connect(func() -> void: get_tree().quit())
	_wire_button_fx("StartRunButton")
	_wire_button_fx("QuitButton")


func _track_animation(node_name: String, float_amount: float, speed: float, wobble: float) -> void:
	var node := find_child(node_name, true, false) as Control
	if node == null:
		return
	_animated_nodes.append({
		"node": node,
		"base": node.position,
		"float": float_amount,
		"speed": speed,
		"rotation": node.rotation_degrees,
		"wobble": wobble,
	})


func _wire_button_fx(button_name: String) -> void:
	var button := find_child(button_name, true, false) as Button
	var holder := find_child("%sGroup" % button_name, true, false) as Control
	var frame := find_child("%sFrame" % button_name, true, false) as TextureRect
	if button == null or holder == null or frame == null or button.disabled:
		return
	button.mouse_entered.connect(func() -> void:
		_tween_button_holder(holder, frame, Vector2(1.045, 1.045), Color(1.18, 1.08, 0.86, 1.0), 0.10)
	)
	button.mouse_exited.connect(func() -> void:
		_tween_button_holder(holder, frame, Vector2.ONE, Color.WHITE, 0.13)
	)
	button.button_down.connect(func() -> void:
		_tween_button_holder(holder, frame, Vector2(0.97, 0.97), Color(1.35, 0.92, 0.70, 1.0), 0.06)
	)
	button.button_up.connect(func() -> void:
		_tween_button_holder(holder, frame, Vector2(1.045, 1.045), Color(1.18, 1.08, 0.86, 1.0), 0.08)
	)


func _build_menu() -> void:
	for child in get_children():
		child.queue_free()
	_animated_nodes.clear()

	var bg := TextureRect.new()
	bg.name = "BG_WarTentTable"
	bg.texture = BG_TEXTURE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var atmosphere: LayeredBackground = LayeredBackgroundScript.new()
	atmosphere.name = "BG_Atmosphere"
	atmosphere.variant = "main_menu"
	atmosphere.show_shader_base = false
	atmosphere.show_banners = false
	atmosphere.show_symbols = false
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(atmosphere)

	var decoration_layer := Control.new()
	decoration_layer.name = "DecorationLayer"
	decoration_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decoration_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decoration_layer)

	var interact_layer := Control.new()
	interact_layer.name = "InteractionLayer"
	interact_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(interact_layer)

	var fx_layer := Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx_layer)

	_add_sprite(decoration_layer, "LeftBannerSprite", RECT_BANNER_LEFT, Vector2(34, 36), -3.0, 1.5, 0.8, 1.4)
	_add_sprite(decoration_layer, "RightBannerSprite", RECT_BANNER_RIGHT, Vector2(556, 38), 3.0, 1.5, 0.85, 1.4)
	_add_sprite(decoration_layer, "JadeStatueLeftSprite", RECT_JADE_DRAGON, Vector2(32, 184), -1.5, 2.2, 0.9, 1.2)
	_add_sprite(decoration_layer, "LanternRightSprite", RECT_LANTERN, Vector2(548, 166), 1.5, 3.0, 1.1, 1.8)
	_add_sprite(decoration_layer, "CoinStacksLeftSprite", RECT_COINS, Vector2(32, 284), -2.5, 2.0, 1.0, 1.2)
	_add_sprite(decoration_layer, "CoinStacksRightSprite", RECT_COINS, Vector2(512, 284), 2.0, 2.0, 1.05, 1.2)
	_add_sprite(decoration_layer, "MenuTileClusterSprite", RECT_TILE_CLUSTER, Vector2(470, 242), -3.0, 2.4, 0.95, 1.3)

	var logo_sprite := _add_sprite(decoration_layer, "LogoSprite", RECT_TOP_BANNER, Vector2(272, 30), 0.0, 1.8, 0.75, 0.6)
	logo_sprite.modulate = Color(1.0, 0.86, 0.68, 0.92)

	main_title = Label.new()
	main_title.name = "MainTitle"
	main_title.text = "Sangoku\nMahjong"
	main_title.position = Vector2(186, 30)
	main_title.size = Vector2(268, 95)
	main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_title.add_theme_font_size_override("font_size", 41)
	main_title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.14))
	main_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.88))
	main_title.add_theme_constant_override("shadow_offset_x", 4)
	main_title.add_theme_constant_override("shadow_offset_y", 4)
	interact_layer.add_child(main_title)

	subtitle_label = Label.new()
	subtitle_label.name = "MainSubtitle"
	subtitle_label.text = "Prototype Build"
	subtitle_label.position = Vector2(243, 318)
	subtitle_label.size = Vector2(154, 20)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 12)
	subtitle_label.add_theme_color_override("font_color", Color(0.46, 1.0, 0.56))
	interact_layer.add_child(subtitle_label)

	_add_menu_button(interact_layer, "StartRunButton", "Start Run", Vector2(278, 150), RECT_RED_BUTTON, false)
	_add_menu_button(interact_layer, "CollectionButton", "Collection", Vector2(276, 192), RECT_GREEN_BUTTON, true)
	_add_menu_button(interact_layer, "OptionsButton", "Options", Vector2(276, 230), RECT_GREEN_BUTTON, true)
	_add_menu_button(interact_layer, "QuitButton", "Quit", Vector2(276, 268), RECT_GREEN_BUTTON, false)

	_add_stat_panel(interact_layer, "HighestScorePanel", "HighestScoreValue", "HIGHEST SCORE", "128,760", Vector2(26, 306), RECT_SCORE_PANEL)
	_add_stat_panel(interact_layer, "BonusPanel", "BonusMultiplierValue", "BONUS MULTIPLIER", "x12", Vector2(540, 306), RECT_BONUS_PANEL)

	_add_menu_tile(interact_layer, "MenuTile_Wan_01", "萬", Vector2(143, 230), Color(0.72, 0.04, 0.04), -6.0)
	_add_menu_tile(interact_layer, "MenuTile_Fa_01", "發", Vector2(444, 220), Color(0.0, 0.50, 0.15), -4.0)
	_add_menu_tile(interact_layer, "MenuTile_Dong_01", "東", Vector2(540, 224), Color(0.05, 0.05, 0.05), 7.0)

	var seal := Label.new()
	seal.name = "TopSealCharacter"
	seal.text = "漢"
	seal.position = Vector2(292, 7)
	seal.size = Vector2(56, 44)
	seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	seal.add_theme_font_size_override("font_size", 34)
	seal.add_theme_color_override("font_color", Color(0.98, 0.78, 0.28, 0.72))
	fx_layer.add_child(seal)


func _add_menu_button(parent: Control, node_name: String, label_text: String, position: Vector2, frame_region: Rect2, disabled := false) -> void:
	var holder := Control.new()
	holder.name = "%sGroup" % node_name
	holder.position = position
	holder.size = _scaled_region_size(frame_region)
	holder.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(holder)

	var frame := TextureRect.new()
	frame.name = "%sFrame" % node_name
	frame.texture = _atlas_texture(frame_region)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.modulate = Color(0.55, 0.55, 0.55, 0.78) if disabled else Color.WHITE
	holder.add_child(frame)

	var button := Button.new()
	button.name = node_name
	button.text = label_text
	button.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.disabled = disabled
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(1.0, 0.91, 0.62))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.68, 0.62, 0.72))
	_apply_transparent_button_style(button)
	holder.add_child(button)

	if node_name == "StartRunButton":
		button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
		)
	elif node_name == "QuitButton":
		button.pressed.connect(func() -> void: get_tree().quit())

	if not disabled:
		button.mouse_entered.connect(func() -> void:
			_tween_button_holder(holder, frame, Vector2(1.045, 1.045), Color(1.18, 1.08, 0.86, 1.0), 0.10)
		)
		button.mouse_exited.connect(func() -> void:
			_tween_button_holder(holder, frame, Vector2.ONE, Color.WHITE, 0.13)
		)
		button.button_down.connect(func() -> void:
			_tween_button_holder(holder, frame, Vector2(0.97, 0.97), Color(1.35, 0.92, 0.70, 1.0), 0.06)
		)
		button.button_up.connect(func() -> void:
			_tween_button_holder(holder, frame, Vector2(1.045, 1.045), Color(1.18, 1.08, 0.86, 1.0), 0.08)
		)


func _add_stat_panel(parent: Control, panel_name: String, value_name: String, caption: String, value: String, position: Vector2, region: Rect2) -> void:
	var panel := Control.new()
	panel.name = panel_name
	panel.position = position
	panel.size = _scaled_region_size(region)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel)

	var frame := TextureRect.new()
	frame.name = "%sFrame" % panel_name
	frame.texture = _atlas_texture(region)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(frame)

	var caption_label := Label.new()
	caption_label.name = "%sCaption" % panel_name
	caption_label.text = caption
	caption_label.position = Vector2(36, 7)
	caption_label.size = Vector2(panel.size.x - 44, 14)
	caption_label.add_theme_font_size_override("font_size", 10)
	caption_label.add_theme_color_override("font_color", Color(0.54, 1.0, 0.56) if value_name == "HighestScoreValue" else Color(1.0, 0.36, 0.18))
	panel.add_child(caption_label)

	var value_label := Label.new()
	value_label.name = value_name
	value_label.text = value
	value_label.position = Vector2(36, 18)
	value_label.size = Vector2(panel.size.x - 44, 24)
	value_label.add_theme_font_size_override("font_size", 21)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.18) if value_name == "HighestScoreValue" else Color(1.0, 0.22, 0.10))
	value_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	value_label.add_theme_constant_override("shadow_offset_x", 2)
	value_label.add_theme_constant_override("shadow_offset_y", 2)
	panel.add_child(value_label)


func _add_menu_tile(parent: Control, node_name: String, text: String, position: Vector2, color: Color, rotation := 0.0) -> void:
	var holder := Control.new()
	holder.name = node_name
	holder.position = position
	holder.size = _scaled_region_size(RECT_TILE_BASE)
	holder.rotation_degrees = rotation
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	_animated_nodes.append({"node": holder, "base": position, "float": 2.2, "speed": 1.0, "rotation": rotation, "wobble": 1.4})

	var tile := TextureRect.new()
	tile.name = "%sBase" % node_name
	tile.texture = _atlas_texture(RECT_TILE_BASE)
	tile.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tile.stretch_mode = TextureRect.STRETCH_SCALE
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(tile)

	var glyph := Label.new()
	glyph.name = "%sGlyph" % node_name
	glyph.text = text
	glyph.position = Vector2(5, 8)
	glyph.size = Vector2(36, 38)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.add_theme_font_size_override("font_size", 25)
	glyph.add_theme_color_override("font_color", color)
	holder.add_child(glyph)


func _add_sprite(parent: Control, node_name: String, region: Rect2, position: Vector2, rotation := 0.0, float_amount := 0.0, speed := 1.0, wobble := 0.0) -> TextureRect:
	var sprite := TextureRect.new()
	var scaled_size := _scaled_region_size(region)
	sprite.name = node_name
	sprite.texture = _atlas_texture(region)
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.position = position
	sprite.size = scaled_size
	sprite.custom_minimum_size = scaled_size
	sprite.rotation_degrees = rotation
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sprite)
	sprite.size = scaled_size
	if float_amount > 0.0 or wobble > 0.0:
		_animated_nodes.append({"node": sprite, "base": position, "float": float_amount, "speed": speed, "rotation": rotation, "wobble": wobble})
	return sprite


func _scaled_region_size(region: Rect2) -> Vector2:
	return region.size * UI_ASSET_SCALE


func _atlas_texture(region: Rect2) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ASSET_SHEET
	texture.region = region
	return texture


func _apply_transparent_button_style(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)


func _tween_button_holder(holder: Control, frame: TextureRect, target_scale: Vector2, target_modulate: Color, duration: float) -> void:
	holder.pivot_offset = holder.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(holder, "scale", target_scale, duration)
	tween.tween_property(frame, "modulate", target_modulate, duration)
