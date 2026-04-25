extends Control

const AnimatedButtonScript = preload("res://src/ui/animated_button.gd")
const TileCardScript = preload("res://src/ui/tile_card.gd")
const ScorePopupScript = preload("res://src/ui/score_popup.gd")

const ENGLISH_PATTERNS := {
	"single": "SINGLE",
	"pair": "PAIR",
	"taatsu": "OPEN WAIT",
	"triplet": "TRIPLET",
	"sequence": "SEQUENCE",
	"two_pairs": "TWO PAIRS",
	"sanshoku_set": "TRI-SUIT SET",
	"iipeikou": "DOUBLE RUN",
	"kan": "KAN",
	"iitsu": "FULL STRAIGHT",
	"chinitsu_group": "PURE COLOR",
	"yakuman": "YAKUMAN",
}

var battle: BattleState
var selected_cards: Array[TileCard] = []
var score_label: Label
var round_label: Label
var target_label: Label
var preview_pattern_label: Label
var preview_score_label: Label
var preview_base_label: Label
var preview_mult_label: Label
var play_button: Button
var hand_row: HBoxContainer
var play_area: PanelContainer
var burst_label: Label
var screen_shake_layer: Control
var _time := 0.0
var _last_preview: Dictionary = {}


func _ready() -> void:
	battle = BattleState.new(320, 4242)
	battle.hand.sort_in_place()
	_build_battle_ui()
	_refresh_hand()
	_update_preview()


func _process(delta: float) -> void:
	_time += delta
	if play_area != null:
		play_area.rotation_degrees = sin(_time * 1.5) * 0.35


func _build_battle_ui() -> void:
	for child in get_children():
		child.queue_free()

	screen_shake_layer = Control.new()
	screen_shake_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_shake_layer)

	var background := ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.material = _make_battle_background_material()
	screen_shake_layer.add_child(background)

	var top_hud := HBoxContainer.new()
	top_hud.position = Vector2(12, 8)
	top_hud.size = Vector2(616, 38)
	top_hud.add_theme_constant_override("separation", 8)
	screen_shake_layer.add_child(top_hud)

	round_label = _hud_label("Round 1 / 4")
	score_label = _hud_label("Score 0")
	target_label = _hud_label("Target 320")
	top_hud.add_child(round_label)
	top_hud.add_child(score_label)
	top_hud.add_child(target_label)

	var generals_panel := PanelContainer.new()
	generals_panel.position = Vector2(14, 52)
	generals_panel.size = Vector2(430, 48)
	generals_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.08, 0.04, 0.045, 0.82), Color(0.58, 0.24, 0.12), 2))
	screen_shake_layer.add_child(generals_panel)

	var generals := HBoxContainer.new()
	generals.add_theme_constant_override("separation", 6)
	generals_panel.add_child(generals)
	for label_text in ["GENERAL SLOT", "+BASE", "xMULT", "CHAIN"]:
		var label := _small_badge(label_text)
		generals.add_child(label)

	play_area = PanelContainer.new()
	play_area.position = Vector2(20, 108)
	play_area.size = Vector2(402, 132)
	play_area.add_theme_stylebox_override("panel", _panel_box(Color(0.10, 0.025, 0.04, 0.9), Color(0.93, 0.52, 0.16), 3))
	screen_shake_layer.add_child(play_area)

	var play_stack := VBoxContainer.new()
	play_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	play_stack.add_theme_constant_override("separation", 6)
	play_area.add_child(play_stack)

	var play_title := Label.new()
	play_title.text = "PLAY AREA"
	play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_title.add_theme_font_size_override("font_size", 13)
	play_title.add_theme_color_override("font_color", Color(0.7, 0.96, 0.78))
	play_stack.add_child(play_title)

	burst_label = Label.new()
	burst_label.text = "SELECT A SET"
	burst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	burst_label.add_theme_font_size_override("font_size", 28)
	burst_label.add_theme_color_override("font_color", Color(1.0, 0.76, 0.24))
	burst_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	burst_label.add_theme_constant_override("shadow_offset_x", 3)
	burst_label.add_theme_constant_override("shadow_offset_y", 3)
	play_stack.add_child(burst_label)

	var right_panel := PanelContainer.new()
	right_panel.position = Vector2(456, 58)
	right_panel.size = Vector2(160, 236)
	right_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.055, 0.055, 0.07, 0.93), Color(0.12, 0.72, 0.48), 2))
	screen_shake_layer.add_child(right_panel)

	var preview := VBoxContainer.new()
	preview.add_theme_constant_override("separation", 7)
	right_panel.add_child(preview)

	var preview_title := _section_label("Score Preview")
	preview.add_child(preview_title)
	preview_pattern_label = _value_label("Select tiles")
	preview_base_label = _value_label("Base 0")
	preview_mult_label = _value_label("Multiplier x0")
	preview_score_label = _value_label("Score 0")
	preview.add_child(preview_pattern_label)
	preview.add_child(preview_base_label)
	preview.add_child(preview_mult_label)
	preview.add_child(preview_score_label)

	play_button = AnimatedButtonScript.new()
	play_button.text = "Play Set"
	play_button.custom_minimum_size = Vector2(128, 36)
	play_button.pressed.connect(_on_play_pressed)
	preview.add_child(play_button)

	var back_button: Button = AnimatedButtonScript.new()
	back_button.text = "Menu"
	back_button.custom_minimum_size = Vector2(128, 30)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/scenes/main_menu/main.tscn"))
	preview.add_child(back_button)

	hand_row = HBoxContainer.new()
	hand_row.position = Vector2(12, 292)
	hand_row.size = Vector2(616, 62)
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 7)
	screen_shake_layer.add_child(hand_row)

	var scanlines := ColorRect.new()
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanlines.material = _make_scanline_material()
	add_child(scanlines)


func _refresh_hand() -> void:
	for child in hand_row.get_children():
		child.queue_free()
	selected_cards.clear()
	battle.hand.sort_in_place()
	for i in range(battle.hand.tiles.size()):
		var card: TileCard = TileCardScript.new()
		card.setup(battle.hand.tiles[i], i)
		card.card_pressed.connect(_on_tile_pressed)
		hand_row.add_child(card)
	_update_hud()


func _on_tile_pressed(card: TileCard) -> void:
	if selected_cards.has(card):
		selected_cards.erase(card)
		card.set_selected(false)
	elif selected_cards.size() < TurnState.MAX_PLAYED_TILES:
		selected_cards.append(card)
		card.set_selected(true)
		card.flash()
	_update_preview()


func _update_preview() -> void:
	var tiles := _selected_tiles()
	_last_preview = PatternMatcher.match_pattern(tiles)
	if _last_preview.is_empty():
		preview_pattern_label.text = "Invalid Set" if not tiles.is_empty() else "Select tiles"
		preview_base_label.text = "Base 0"
		preview_mult_label.text = "Multiplier x0"
		preview_score_label.text = "Score 0"
		play_button.disabled = true
		burst_label.text = "SELECT A SET" if tiles.is_empty() else "INVALID SET"
		return

	var score := Scorer.score(_last_preview)
	var english_name := _pattern_name(_last_preview)
	preview_pattern_label.text = "Pattern  " + english_name
	preview_base_label.text = "Base  %d" % int(score.get("base_score", 0))
	preview_mult_label.text = "Multiplier  x%s" % _format_mult(float(score.get("pattern_mult", 0.0)))
	preview_score_label.text = "Score  %d" % int(score.get("final_score", 0))
	play_button.disabled = false
	burst_label.text = english_name


func _on_play_pressed() -> void:
	if _last_preview.is_empty() or selected_cards.is_empty():
		return
	var tiles := _selected_tiles()
	var result := battle.play_turn(tiles)
	if not result.get("valid", false):
		_show_popup("CAN'T PLAY", Color(1.0, 0.2, 0.2))
		return

	var pattern_text := _pattern_name(_last_preview)
	var gained := int(result.get("final_score", 0))
	_play_resolution_animation(pattern_text, gained)
	selected_cards.clear()
	_refresh_hand()
	_update_preview()


func _play_resolution_animation(pattern_text: String, gained: int) -> void:
	burst_label.text = pattern_text + "\n+" + str(gained)
	burst_label.scale = Vector2(0.55, 0.55)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(burst_label, "scale", Vector2(1.25, 1.25), 0.16)
	tween.tween_property(burst_label, "modulate", Color(1.0, 0.36, 0.22), 0.08)
	tween.chain().tween_property(burst_label, "modulate", Color.WHITE, 0.22)
	_show_popup("+" + str(gained), Color(1.0, 0.83, 0.2))
	_shake_screen()


func _show_popup(message: String, color: Color) -> void:
	var popup: ScorePopup = ScorePopupScript.new()
	add_child(popup)
	popup.popup(message, Vector2(246, 178), color)


func _shake_screen() -> void:
	var tween := create_tween()
	tween.tween_property(screen_shake_layer, "position", Vector2(5, -4), 0.035)
	tween.tween_property(screen_shake_layer, "position", Vector2(-5, 3), 0.035)
	tween.tween_property(screen_shake_layer, "position", Vector2(3, 4), 0.035)
	tween.tween_property(screen_shake_layer, "position", Vector2.ZERO, 0.05)


func _selected_tiles() -> Array:
	var tiles := []
	for card in selected_cards:
		tiles.append(card.tile)
	return tiles


func _update_hud() -> void:
	round_label.text = "Round %d / %d" % [min(battle.current_turn, BattleState.MAX_TURNS), BattleState.MAX_TURNS]
	score_label.text = "Score %d" % battle.total_score
	target_label.text = "Target %d" % battle.target_score


func _pattern_name(pattern: Dictionary) -> String:
	return ENGLISH_PATTERNS.get(pattern.get("id", ""), "UNKNOWN")


func _format_mult(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value


func _hud_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _section_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.38, 1.0, 0.72))
	return label


func _value_label(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _small_badge(label_text: String) -> Label:
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(92, 28)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.55))
	label.add_theme_stylebox_override("normal", _panel_box(Color(0.16, 0.08, 0.10, 0.9), Color(0.68, 0.31, 0.12), 1))
	return label


func _panel_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	box.shadow_size = 5
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box


func _make_battle_background_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float wood = sin((uv.x * 18.0 + sin(uv.y * 9.0)) + TIME * 0.12) * 0.035;
	float pulse = sin(TIME * 2.6 + uv.x * 8.0 + uv.y * 4.0) * 0.5 + 0.5;
	vec3 base = mix(vec3(0.055, 0.018, 0.018), vec3(0.16, 0.055, 0.035), uv.y);
	vec3 jade = vec3(0.0, 0.35, 0.22) * (1.0 - smoothstep(0.05, 0.82, distance(uv, vec2(0.72, 0.42))));
	vec3 ember = vec3(0.85, 0.18, 0.05) * pulse * 0.12;
	COLOR = vec4(base + wood + jade * 0.28 + ember, 1.0);
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
	float scan = max(sin((UV.y + TIME * 0.2) * 720.0), 0.0);
	float vignette = smoothstep(0.35, 0.82, distance(UV, vec2(0.5)));
	COLOR = vec4(0.0, 0.0, 0.0, scan * 0.06 + vignette * 0.28);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
