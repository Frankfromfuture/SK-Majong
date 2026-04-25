class_name ModifierBadge
extends PanelContainer

var title_label: Label


func setup(label_text: String, width: float = 90.0) -> void:
	custom_minimum_size = Vector2(width, 28)
	add_theme_stylebox_override("panel", _box(Color(0.10, 0.05, 0.065, 0.92), Color(0.73, 0.30, 0.10), 1))
	title_label = Label.new()
	title_label.name = "BadgeText"
	title_label.text = label_text
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 10)
	title_label.add_theme_color_override("font_color", Color(0.94, 0.86, 0.48))
	add_child(title_label)


func pulse() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(self, "scale", Vector2.ONE, 0.14)


func _box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 4
	box.corner_radius_top_right = 4
	box.corner_radius_bottom_left = 4
	box.corner_radius_bottom_right = 4
	box.shadow_color = Color(0, 0, 0, 0.48)
	box.shadow_size = 4
	box.content_margin_left = 6
	box.content_margin_right = 6
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box
