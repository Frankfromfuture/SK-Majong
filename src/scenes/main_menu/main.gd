extends Control

const AnimatedButtonScript = preload("res://src/ui/animated_button.gd")

var _time := 0.0
var _title: Label
var _subtitle: Label


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_build_menu()


func _process(delta: float) -> void:
	_time += delta
	if _title != null:
		_title.position.x = 58.0 + sin(_time * 1.7) * 2.0
	if _subtitle != null:
		_subtitle.modulate.a = 0.65 + sin(_time * 3.1) * 0.22


func _build_menu() -> void:
	for child in get_children():
		child.queue_free()

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.material = _make_background_material()
	add_child(background)

	var scanlines := ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanlines.material = _make_scanline_material()
	add_child(scanlines)

	var table_glow := ColorRect.new()
	table_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	table_glow.color = Color(0.08, 0.02, 0.03, 0.32)
	add_child(table_glow)

	var left_panel := PanelContainer.new()
	left_panel.position = Vector2(38, 40)
	left_panel.size = Vector2(284, 260)
	left_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.12, 0.035, 0.052, 0.92), Color(0.86, 0.48, 0.18), 3))
	add_child(left_panel)

	var menu := VBoxContainer.new()
	menu.add_theme_constant_override("separation", 14)
	left_panel.add_child(menu)

	_title = Label.new()
	_title.text = "Sangoku\nMahjong"
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.24))
	_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	_title.add_theme_constant_override("shadow_offset_x", 3)
	_title.add_theme_constant_override("shadow_offset_y", 3)
	menu.add_child(_title)

	_subtitle = Label.new()
	_subtitle.text = "Tile scoring roguelike prototype"
	_subtitle.add_theme_font_size_override("font_size", 12)
	_subtitle.add_theme_color_override("font_color", Color(0.76, 0.95, 0.78))
	menu.add_child(_subtitle)

	var start_button: Button = AnimatedButtonScript.new()
	start_button.text = "Start Run"
	start_button.custom_minimum_size = Vector2(210, 42)
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
	)
	menu.add_child(start_button)

	var quit_button: Button = AnimatedButtonScript.new()
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(210, 34)
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	menu.add_child(quit_button)

	var marquee := Label.new()
	marquee.text = "CRIT CHAIN  xMULT  GOLDEN SET"
	marquee.position = Vector2(352, 42)
	marquee.size = Vector2(230, 28)
	marquee.rotation_degrees = -4.0
	marquee.add_theme_font_size_override("font_size", 13)
	marquee.add_theme_color_override("font_color", Color(1.0, 0.36, 0.3))
	add_child(marquee)

	for i in range(7):
		var chip := Label.new()
		chip.text = ["万", "筒", "索"][i % 3]
		chip.position = Vector2(350 + i * 31, 122 + sin(i) * 34)
		chip.rotation_degrees = -12.0 + i * 5.0
		chip.add_theme_font_size_override("font_size", 28)
		chip.add_theme_color_override("font_color", [Color(0.92, 0.18, 0.18), Color(0.2, 0.7, 1.0), Color(0.25, 0.9, 0.44)][i % 3])
		add_child(chip)


func _make_background_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float pulse = sin(TIME * 1.8 + uv.x * 8.0) * 0.5 + 0.5;
	float banner = smoothstep(0.18, 0.22, abs(sin((uv.x + uv.y * 0.25 + TIME * 0.04) * 18.0)));
	vec3 base = mix(vec3(0.035, 0.01, 0.018), vec3(0.18, 0.035, 0.055), uv.y);
	vec3 jade = vec3(0.02, 0.28, 0.19) * (1.0 - distance(uv, vec2(0.78, 0.58)));
	vec3 bronze = vec3(0.75, 0.32, 0.08) * pulse * 0.18;
	COLOR = vec4(base + jade * 0.38 + bronze + banner * 0.035, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _make_scanline_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float line = sin((UV.y + TIME * 0.18) * 720.0);
	float vignette = distance(UV, vec2(0.5));
	COLOR = vec4(0.0, 0.0, 0.0, 0.10 + max(line, 0.0) * 0.07 + vignette * 0.16);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _panel_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 6
	box.corner_radius_top_right = 6
	box.corner_radius_bottom_left = 6
	box.corner_radius_bottom_right = 6
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	box.shadow_size = 8
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 18
	box.content_margin_bottom = 18
	return box
