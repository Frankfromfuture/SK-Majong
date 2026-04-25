class_name PreviewRow
extends HBoxContainer

var label_node: Label
var value_node: Label


func setup(label_text: String, value_text: String, value_name: String) -> void:
	add_theme_constant_override("separation", 4)
	label_node = Label.new()
	label_node.name = label_text.replace(" ", "") + "Label"
	label_node.text = label_text
	label_node.custom_minimum_size = Vector2(68, 18)
	label_node.add_theme_font_size_override("font_size", 10)
	label_node.add_theme_color_override("font_color", Color(0.68, 0.84, 0.68))
	add_child(label_node)

	value_node = Label.new()
	value_node.name = value_name
	value_node.text = value_text
	value_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_node.add_theme_font_size_override("font_size", 11)
	value_node.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	value_node.add_theme_color_override("font_shadow_color", Color.BLACK)
	value_node.add_theme_constant_override("shadow_offset_x", 1)
	value_node.add_theme_constant_override("shadow_offset_y", 1)
	add_child(value_node)


func set_value(value_text: String) -> void:
	value_node.text = value_text


func flash(color: Color = Color(0.2, 1.0, 0.58)) -> void:
	var tween := create_tween()
	tween.tween_property(value_node, "modulate", color, 0.06)
	tween.tween_property(value_node, "modulate", Color.WHITE, 0.18)
