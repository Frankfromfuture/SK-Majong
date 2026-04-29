extends Control

var is_win := false
var turn_number := 0
var title_label: Label
var subtitle_label: Label
var _time := 0.0


func _ready() -> void:
	_wire_existing_ui()


func _process(delta: float) -> void:
	_time += delta
	if title_label != null:
		title_label.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.02)
	if subtitle_label != null:
		subtitle_label.modulate.a = 0.6 + sin(_time * 3.0) * 0.2


func setup(p_is_win: bool, p_turn_number: int) -> void:
	is_win = p_is_win
	turn_number = p_turn_number
	if is_inside_tree():
		_apply_result_state()


func _wire_existing_ui() -> void:
	title_label = find_child("GameOverTitle", true, false) as Label
	subtitle_label = find_child("GameOverSubtitle", true, false) as Label
	var play_again_button := find_child("PlayAgainButton", true, false) as Button
	if play_again_button != null:
		play_again_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
		)
	var main_menu_button := find_child("MainMenuButton", true, false) as Button
	if main_menu_button != null:
		main_menu_button.pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://src/scenes/main_menu/main.tscn")
		)
	_apply_result_state()


func _apply_result_state() -> void:
	var title_text := "VICTORY" if is_win else "DEFEAT"
	var title_color := Color(1.0, 0.86, 0.22) if is_win else Color(1.0, 0.28, 0.18)
	if title_label != null:
		title_label.text = title_text
		title_label.add_theme_color_override("font_color", title_color)
	if subtitle_label != null:
		subtitle_label.text = "Enemy warlord defeated!" if is_win else "Duel failed after %d turns" % turn_number
	var round_label := find_child("RoundInfoLabel", true, false) as Label
	if round_label != null:
		round_label.text = "Won on turn %d" % turn_number if is_win else "Reached turn %d" % turn_number
	var bg := find_child("GameOverBackground", true, false) as Panel
	if bg != null:
		bg.add_theme_stylebox_override("panel", _box(
			Color(0.02, 0.04, 0.03) if is_win else Color(0.025, 0.018, 0.022),
			Color(0.15, 0.08, 0.04),
			2,
			0
		))


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	var root := Control.new()
	root.name = "GameOverRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Background
	var bg := Panel.new()
	bg.name = "GameOverBackground"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override("panel", _box(
		Color(0.025, 0.018, 0.022) if not is_win else Color(0.02, 0.04, 0.03),
		Color(0.15, 0.08, 0.04), 2, 0
	))
	root.add_child(bg)

	# Result panel
	_panel(root, "ResultPanel", Rect2(170, 80, 300, 200), Color(0.08, 0.10, 0.08, 0.92))

	# Title
	var title_text := "VICTORY" if is_win else "DEFEAT"
	var title_color := Color(1.0, 0.86, 0.22) if is_win else Color(1.0, 0.28, 0.18)
	title_label = _label(root, "GameOverTitle", title_text, Rect2(170, 100, 300, 50), 36, title_color, HORIZONTAL_ALIGNMENT_CENTER)

	# Subtitle
	var sub_text := "Enemy warlord defeated!" if is_win else "Duel failed after %d turns" % turn_number
	subtitle_label = _label(root, "GameOverSubtitle", sub_text, Rect2(170, 155, 300, 24), 14, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_CENTER)

	# Round info
	_label(root, "RoundInfoLabel", "Won on turn %d" % turn_number if is_win else "Reached turn %d" % turn_number, Rect2(170, 190, 300, 20), 11, Color(0.62, 0.65, 0.62), HORIZONTAL_ALIGNMENT_CENTER)

	# Buttons
	_button(root, "PlayAgainButton", "PLAY AGAIN", Rect2(220, 228, 90, 28), func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
	)
	_button(root, "MainMenuButton", "MAIN MENU", Rect2(330, 228, 90, 28), func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/main_menu/main.tscn")
	)

	# Decorative label
	_label(root, "SealCharacter", "漢", Rect2(292, 296, 56, 44), 28, Color(0.98, 0.78, 0.28, 0.42), HORIZONTAL_ALIGNMENT_CENTER)


func _panel(parent: Control, node_name: String, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(color, Color(0.78, 0.42, 0.12), 2, 6))
	parent.add_child(panel)
	return panel


func _label(parent: Control, node_name: String, text: String, rect: Rect2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.72))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label


func _button(parent: Control, node_name: String, text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_stylebox_override("normal", _box(Color(0.45, 0.09, 0.05), Color(0.8, 0.42, 0.12), 1, 4))
	button.add_theme_stylebox_override("hover", _box(Color(0.66, 0.13, 0.07), Color(1.0, 0.72, 0.18), 1, 4))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	box.shadow_size = 4
	return box
