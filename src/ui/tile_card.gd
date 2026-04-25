class_name TileCard
extends Button

signal card_pressed(card: TileCard)

var tile: Tile
var tile_index := -1
var selected := false
var suit_color := Color.WHITE


func setup(p_tile: Tile, p_index: int) -> void:
	tile = p_tile
	tile_index = p_index
	text = _tile_text()
	suit_color = _suit_color()
	custom_minimum_size = Vector2(36, 54)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	focus_mode = Control.FOCUS_NONE
	_update_style()


func _ready() -> void:
	pivot_offset = custom_minimum_size * 0.5
	pressed.connect(func() -> void: card_pressed.emit(self))
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_selected(value: bool) -> void:
	selected = value
	_update_style()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", -11.0 if selected else 0.0, 0.12)
	tween.tween_property(self, "rotation_degrees", randf_range(-4.0, 4.0) if selected else 0.0, 0.12)
	tween.tween_property(self, "scale", Vector2(1.08, 1.08) if selected else Vector2.ONE, 0.12)


func flash() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "self_modulate", Color(1.0, 0.86, 0.28), 0.05)
	tween.tween_property(self, "self_modulate", Color.WHITE, 0.16)


func _on_mouse_entered() -> void:
	if selected:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)


func _on_mouse_exited() -> void:
	if selected:
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _tile_text() -> String:
	if tile == null:
		return "?"
	return "%d\n%s" % [tile.rank, Tile.SUIT_NAMES[tile.suit]]


func _suit_color() -> Color:
	if tile == null:
		return Color.WHITE
	match tile.suit:
		Tile.Suit.MAN:
			return Color(0.92, 0.19, 0.18)
		Tile.Suit.PIN:
			return Color(0.17, 0.58, 0.98)
		Tile.Suit.SOU:
			return Color(0.18, 0.76, 0.42)
	return Color.WHITE


func _update_style() -> void:
	add_theme_font_size_override("font_size", 16)
	add_theme_color_override("font_color", suit_color)
	add_theme_color_override("font_hover_color", suit_color.lightened(0.25))
	add_theme_color_override("font_pressed_color", Color(0.05, 0.03, 0.03))
	var fill := Color(0.94, 0.86, 0.62) if not selected else Color(1.0, 0.92, 0.35)
	var border := Color(0.34, 0.13, 0.08) if not selected else Color(1.0, 0.72, 0.22)
	add_theme_stylebox_override("normal", _make_box(fill, border, 2))
	add_theme_stylebox_override("hover", _make_box(fill.lightened(0.08), Color(1.0, 0.82, 0.3), 3))
	add_theme_stylebox_override("pressed", _make_box(Color(0.88, 0.52, 0.22), Color(1.0, 0.9, 0.48), 3))


func _make_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	box.shadow_size = 4
	box.content_margin_top = 5
	box.content_margin_bottom = 5
	return box
