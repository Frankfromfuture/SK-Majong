class_name ScorePopup
extends Label


func popup(message: String, start_position: Vector2, color: Color = Color(1.0, 0.84, 0.24)) -> void:
	text = message
	position = start_position
	modulate = color
	scale = Vector2(0.6, 0.6)
	add_theme_font_size_override("font_size", 24)
	add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.75))
	add_theme_constant_override("shadow_offset_x", 2)
	add_theme_constant_override("shadow_offset_y", 2)
	z_index = 50
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.18)
	tween.tween_property(self, "position:y", start_position.y - 38.0, 0.55)
	tween.chain().tween_property(self, "modulate:a", 0.0, 0.28)
	tween.finished.connect(queue_free)
