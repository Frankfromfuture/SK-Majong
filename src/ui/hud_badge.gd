class_name HudBadge
extends PanelContainer

var title_label: Label
var value_label: Label


func setup(title: String, value: String, width: float = 150.0) -> void:
	custom_minimum_size = Vector2(width, 38)
	add_theme_stylebox_override("panel", _box(Color(0.035, 0.060, 0.052, 0.94), Color(0.78, 0.42, 0.12), 2))
	var row := VBoxContainer.new()
	row.name = "BadgeStack"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(0.74, 0.95, 0.74))
	row.add_child(title_label)

	value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 20)
	value_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.26))
	value_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	value_label.add_theme_constant_override("shadow_offset_x", 2)
	value_label.add_theme_constant_override("shadow_offset_y", 2)
	row.add_child(value_label)


func set_value(value: String) -> void:
	if value_label != null:
		value_label.text = value


func pulse(color: Color = Color(1.0, 0.4, 0.18)) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(self, "self_modulate", color, 0.08)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.16)
	tween.parallel().tween_property(self, "self_modulate", Color.WHITE, 0.16)


func _box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 5
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
