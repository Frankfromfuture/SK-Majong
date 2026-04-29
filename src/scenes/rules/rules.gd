extends Control

const PATTERN_ROWS := [
	{"name": "136 tiles", "stage": "1.0", "detail": "No flowers", "enabled": true},
	{"name": "Draw rhythm", "stage": "1.0", "detail": "Last play + 1, max 4", "enabled": true},
	{"name": "Hand cap", "stage": "1.0", "detail": "Discard to 14", "enabled": true},
	{"name": "Single / Scatter", "stage": "1.0", "detail": "Best suited tile only", "enabled": true},
	{"name": "Pair", "stage": "1.0", "detail": "x2.5, no battlefield", "enabled": true},
	{"name": "Sequence", "stage": "1.0", "detail": "x4, battlefield", "enabled": true},
	{"name": "Triplet", "stage": "1.0", "detail": "x5, battlefield", "enabled": true},
	{"name": "Kan", "stage": "1.0", "detail": "x8, battlefield", "enabled": true},
	{"name": "Standard Hu", "stage": "1.0", "detail": "4 melds + pair", "enabled": true},
	{"name": "Total Assault", "stage": "1.0", "detail": "Hu x2, battle continues", "enabled": true},
	{"name": "Honor powers", "stage": "2.0", "detail": "Reserved", "enabled": false},
	{"name": "Special wins", "stage": "2.0", "detail": "Reserved", "enabled": false},
]


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_panel(self, "RulesBackground", Rect2(0, 0, 640, 360), Color(0.035, 0.023, 0.026))
	_label(self, "RulesHeader", "BATTLE RULES V1.0", Rect2(0, 16, 640, 28), 18, Color.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_button(self, "RulesBackButton", "BACK", Rect2(582, 8, 46, 20), _on_back_pressed)

	var px := 214
	var pw := 212
	_panel(self, "PatternListPanel", Rect2(px, 44, pw, 310), Color(0.06, 0.09, 0.07, 0.97))
	_label(self, "PatternListTitle", "RULE MODULES", Rect2(px + 10, 50, pw - 20, 16), 13, Color.YELLOW)
	_label(self, "PatternListSubtitle", "Name              Detail", Rect2(px + 10, 70, pw - 16, 12), 6, Color(0.5, 0.55, 0.5))
	for i in range(PATTERN_ROWS.size()):
		var row: Dictionary = PATTERN_ROWS[i]
		var y := 86 + i * 22
		var color := Color.WHITE if row["enabled"] else Color(0.62, 0.65, 0.62)
		var row_bg := Color(0.16, 0.18, 0.15) if row["enabled"] else Color(0.12, 0.14, 0.12, 0.72)
		_panel(self, "PatternRow_%02d" % i, Rect2(px + 4, y, pw - 8, 18), row_bg)
		_label(self, "PatternRowName_%02d" % i, row["name"], Rect2(px + 10, y, 82, 18), 7, color)
		_label(self, "PatternRowDetail_%02d" % i, row["detail"], Rect2(px + 96, y, 76, 18), 6, color)
		_label(self, "PatternRowProgress_%02d" % i, "ON" if row["enabled"] else row["stage"], Rect2(px + 176, y, 30, 18), 6, color, HORIZONTAL_ALIGNMENT_RIGHT)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")


func _button(parent: Control, node_name: String, text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 8)
	button.add_theme_stylebox_override("normal", _box(Color(0.45, 0.09, 0.05), Color(0.8, 0.42, 0.12), 1, 4))
	button.add_theme_stylebox_override("hover", _box(Color(0.66, 0.13, 0.07), Color(1.0, 0.72, 0.18), 1, 4))
	button.add_theme_stylebox_override("disabled", _box(Color(0.22, 0.16, 0.15), Color(0.28, 0.26, 0.24), 1, 4))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _panel(parent: Control, node_name: String, rect: Rect2, color: Color) -> Panel:
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(color, Color(0.20, 0.12, 0.06), 1, 4))
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
	parent.add_child(label)
	return label


func _box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	box.shadow_size = 3
	return box
