extends Control

const PATTERN_ROWS := [
	{"name": "Standard Win", "stage": "1.0", "level": 1, "base": 0, "mult": "x2", "enabled": true},
	{"name": "All Sequences", "stage": "2.0", "level": 1, "base": 20, "mult": "x1", "enabled": false},
	{"name": "All Triplets", "stage": "2.0", "level": 1, "base": 35, "mult": "x2", "enabled": false},
	{"name": "Mixed Suit", "stage": "2.0", "level": 1, "base": 25, "mult": "x1", "enabled": false},
	{"name": "Pure Suit", "stage": "2.0", "level": 1, "base": 45, "mult": "x3", "enabled": false},
	{"name": "Seven Pairs", "stage": "2.0", "level": 1, "base": 40, "mult": "x2", "enabled": false},
	{"name": "Thirteen Orphans", "stage": "2.0", "level": 1, "base": 88, "mult": "x5", "enabled": false},
	{"name": "Dragon Set", "stage": "2.0", "level": 1, "base": 30, "mult": "x2", "enabled": false},
	{"name": "Wind Set", "stage": "2.0", "level": 1, "base": 30, "mult": "x2", "enabled": false},
	{"name": "Flower Bloom", "stage": "3.0", "level": 1, "base": 20, "mult": "x2", "enabled": false},
	{"name": "Season Cycle", "stage": "3.0", "level": 1, "base": 20, "mult": "x2", "enabled": false},
	{"name": "Warlord Formation", "stage": "4.0", "level": 1, "base": 50, "mult": "x4", "enabled": false},
]


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_build_ui()


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_panel(self, "RulesBackground", Rect2(0, 0, 640, 360), Color(0.035, 0.023, 0.026))
	_label(self, "RulesHeader", "PATTERNS", Rect2(0, 16, 640, 28), 18, Color.YELLOW, HORIZONTAL_ALIGNMENT_CENTER)
	_button(self, "RulesBackButton", "BACK", Rect2(582, 8, 46, 20), _on_back_pressed)

	var px := 214
	var pw := 212
	_panel(self, "PatternListPanel", Rect2(px, 44, pw, 310), Color(0.06, 0.09, 0.07, 0.97))
	_label(self, "PatternListTitle", "PATTERNS", Rect2(px + 10, 50, pw - 20, 16), 13, Color.YELLOW)
	_label(self, "PatternListSubtitle", "Name                 Lv Base Mult", Rect2(px + 10, 70, pw - 16, 12), 6, Color(0.5, 0.55, 0.5))
	for i in range(PATTERN_ROWS.size()):
		var row: Dictionary = PATTERN_ROWS[i]
		var y := 86 + i * 22
		var color := Color.WHITE if row["enabled"] else Color(0.62, 0.65, 0.62)
		var row_bg := Color(0.16, 0.18, 0.15) if row["enabled"] else Color(0.12, 0.14, 0.12, 0.72)
		_panel(self, "PatternRow_%02d" % i, Rect2(px + 4, y, pw - 8, 18), row_bg)
		_label(self, "PatternRowName_%02d" % i, row["name"], Rect2(px + 10, y, 84, 18), 8, color)
		_label(self, "PatternRowLevel_%02d" % i, "Lv.%s" % row["level"], Rect2(px + 98, y, 26, 18), 7, color, HORIZONTAL_ALIGNMENT_CENTER)
		_label(self, "PatternRowBase_%02d" % i, str(row["base"]), Rect2(px + 128, y, 22, 18), 7, color, HORIZONTAL_ALIGNMENT_RIGHT)
		_label(self, "PatternRowMultiplier_%02d" % i, row["mult"], Rect2(px + 154, y, 22, 18), 8, Color(1.0, 0.42, 0.32) if row["enabled"] else color, HORIZONTAL_ALIGNMENT_RIGHT)
		_label(self, "PatternRowProgress_%02d" % i, "ON" if row["enabled"] else row["stage"], Rect2(px + 180, y, 26, 18), 6, color, HORIZONTAL_ALIGNMENT_RIGHT)


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
