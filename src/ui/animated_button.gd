class_name AnimatedButton
extends Button

var normal_color := Color(0.18, 0.08, 0.12, 1.0)
var hover_color := Color(0.75, 0.22, 0.23, 1.0)
var pressed_color := Color(0.95, 0.74, 0.28, 1.0)


func _ready() -> void:
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_refresh_styles(normal_color)


func set_visual_colors(p_normal: Color, p_hover: Color, p_pressed: Color) -> void:
	normal_color = p_normal
	hover_color = p_hover
	pressed_color = p_pressed
	_refresh_styles(normal_color)


func _on_mouse_entered() -> void:
	if disabled:
		return
	_refresh_styles(hover_color)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12)


func _on_mouse_exited() -> void:
	_refresh_styles(normal_color)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)


func _on_button_down() -> void:
	if disabled:
		return
	_refresh_styles(pressed_color)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.06)


func _on_button_up() -> void:
	if disabled:
		return
	_on_mouse_entered()


func _refresh_styles(base_color: Color) -> void:
	add_theme_color_override("font_color", Color(1.0, 0.9, 0.58))
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_pressed_color", Color(0.12, 0.04, 0.05))
	add_theme_font_size_override("font_size", 14)
	add_theme_stylebox_override("normal", _make_box(base_color, Color(0.95, 0.68, 0.22), 2))
	add_theme_stylebox_override("hover", _make_box(hover_color, Color(1.0, 0.88, 0.36), 3))
	add_theme_stylebox_override("pressed", _make_box(pressed_color, Color(1.0, 0.96, 0.56), 3))
	add_theme_stylebox_override("disabled", _make_box(Color(0.12, 0.11, 0.12, 0.85), Color(0.35, 0.31, 0.28), 1))


func _make_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	box.shadow_size = 4
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
