extends Control

const AnimatedButtonScript = preload("res://src/ui/animated_button.gd")
const HudBadgeScript = preload("res://src/ui/hud_badge.gd")
const LayeredBackgroundScript = preload("res://src/ui/layered_background.gd")
const ModifierBadgeScript = preload("res://src/ui/modifier_badge.gd")
const PreviewRowScript = preload("res://src/ui/preview_row.gd")
const ScorePopupScript = preload("res://src/ui/score_popup.gd")
const TileCardScript = preload("res://src/ui/tile_card.gd")

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
var round_badge: HudBadge
var score_badge: HudBadge
var target_badge: HudBadge
var preview_pattern_row: PreviewRow
var preview_base_row: PreviewRow
var preview_mult_row: PreviewRow
var preview_score_row: PreviewRow
var hand_value_label: Label
var discards_left_label: Label
var play_button: Button
var hand_row: HBoxContainer
var play_area: PanelContainer
var play_area_tile_row: HBoxContainer
var score_burst_label: Label
var multiplier_burst_label: Label
var screen_shake_layer: Control
var fx_layer: Control
var _time := 0.0
var _last_preview: Dictionary = {}


func _ready() -> void:
	battle = BattleState.new(60000, 4242)
	battle.hand.sort_in_place()
	_build_battle_ui()
	_refresh_hand()
	_update_preview()


func _process(delta: float) -> void:
	_time += delta
	if play_area != null:
		play_area.rotation_degrees = sin(_time * 1.2) * 0.25
	if score_burst_label != null and selected_cards.is_empty():
		score_burst_label.scale = Vector2.ONE * (1.0 + sin(_time * 2.4) * 0.015)


func _build_battle_ui() -> void:
	for child in get_children():
		child.queue_free()

	screen_shake_layer = Control.new()
	screen_shake_layer.name = "ScreenShakeLayer"
	screen_shake_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen_shake_layer)

	var background: LayeredBackground = LayeredBackgroundScript.new()
	background.name = "BackgroundLayer"
	screen_shake_layer.add_child(background)

	var decoration_layer := Control.new()
	decoration_layer.name = "DecorationLayer"
	decoration_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_shake_layer.add_child(decoration_layer)

	var hud_layer := Control.new()
	hud_layer.name = "HudLayer"
	hud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_shake_layer.add_child(hud_layer)

	var interaction_layer := Control.new()
	interaction_layer.name = "InteractionLayer"
	interaction_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_shake_layer.add_child(interaction_layer)

	fx_layer = Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)

	_build_title_cluster(decoration_layer)
	_build_hud(hud_layer)
	_build_modifier_row(interaction_layer)
	_build_play_area(interaction_layer)
	_build_preview_panel(interaction_layer)
	_build_hand_row(interaction_layer)
	_build_bottom_status(interaction_layer)


func _build_title_cluster(parent: Control) -> void:
	var seal := Label.new()
	seal.name = "BattleSealMark"
	seal.text = "三\n国"
	seal.position = Vector2(16, 20)
	seal.add_theme_font_size_override("font_size", 17)
	seal.add_theme_color_override("font_color", Color(1.0, 0.18, 0.12))
	parent.add_child(seal)

	var title := Label.new()
	title.name = "BattleLogoTitle"
	title.text = "Sangoku\nMahjong"
	title.position = Vector2(52, 26)
	title.size = Vector2(190, 84)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1.0, 0.72, 0.18))
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	parent.add_child(title)


func _build_hud(parent: Control) -> void:
	round_badge = HudBadgeScript.new()
	round_badge.name = "RoundBadge"
	round_badge.setup("ROUND", "1 / 4", 112)
	round_badge.position = Vector2(238, 12)
	parent.add_child(round_badge)

	score_badge = HudBadgeScript.new()
	score_badge.name = "ScoreBadge"
	score_badge.setup("SCORE", "0", 150)
	score_badge.position = Vector2(356, 12)
	score_badge.value_label.name = "ScoreValue"
	parent.add_child(score_badge)

	target_badge = HudBadgeScript.new()
	target_badge.name = "TargetBadge"
	target_badge.setup("TARGET", "60,000", 112)
	target_badge.position = Vector2(512, 12)
	parent.add_child(target_badge)


func _build_modifier_row(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.name = "ModifierRow"
	row.position = Vector2(238, 58)
	row.size = Vector2(294, 34)
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	for data in [["GeneralSlotBadge", "GENERAL SLOT"], ["BaseModBadge", "+BASE"], ["MultModBadge", "xMULT"], ["ChainModBadge", "CHAIN"]]:
		var badge: ModifierBadge = ModifierBadgeScript.new()
		badge.name = data[0]
		badge.setup(data[1], 70 if data[0] != "GeneralSlotBadge" else 100)
		row.add_child(badge)


func _build_play_area(parent: Control) -> void:
	play_area = PanelContainer.new()
	play_area.name = "PlayAreaPanel"
	play_area.position = Vector2(228, 100)
	play_area.size = Vector2(282, 142)
	play_area.add_theme_stylebox_override("panel", _panel_box(Color(0.08, 0.025, 0.03, 0.80), Color(0.95, 0.38, 0.10), 2))
	parent.add_child(play_area)

	var stack := VBoxContainer.new()
	stack.name = "PlayAreaStack"
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 4)
	play_area.add_child(stack)

	var title := Label.new()
	title.name = "PlayAreaTitle"
	title.text = "PLAY AREA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.52, 1.0, 0.68))
	stack.add_child(title)

	score_burst_label = Label.new()
	score_burst_label.name = "ScoreBurstLabel"
	score_burst_label.text = "SELECT A SET"
	score_burst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_burst_label.add_theme_font_size_override("font_size", 28)
	score_burst_label.add_theme_color_override("font_color", Color(1.0, 0.73, 0.18))
	score_burst_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	score_burst_label.add_theme_constant_override("shadow_offset_x", 3)
	score_burst_label.add_theme_constant_override("shadow_offset_y", 3)
	stack.add_child(score_burst_label)

	multiplier_burst_label = Label.new()
	multiplier_burst_label.name = "MultiplierBurstLabel"
	multiplier_burst_label.text = "x0 MULTIPLIER"
	multiplier_burst_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_burst_label.add_theme_font_size_override("font_size", 15)
	multiplier_burst_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58))
	stack.add_child(multiplier_burst_label)

	play_area_tile_row = HBoxContainer.new()
	play_area_tile_row.name = "PlayedTileEchoRow"
	play_area_tile_row.alignment = BoxContainer.ALIGNMENT_CENTER
	play_area_tile_row.add_theme_constant_override("separation", 5)
	stack.add_child(play_area_tile_row)


func _build_preview_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.name = "ScorePreviewPanel"
	panel.position = Vector2(520, 82)
	panel.size = Vector2(112, 198)
	panel.add_theme_stylebox_override("panel", _panel_box(Color(0.030, 0.052, 0.046, 0.95), Color(0.75, 0.38, 0.12), 2))
	parent.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "ScorePreviewStack"
	stack.add_theme_constant_override("separation", 5)
	panel.add_child(stack)

	var title := Label.new()
	title.name = "ScorePreviewTitle"
	title.text = "Score Preview"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.54, 1.0, 0.68))
	stack.add_child(title)

	preview_pattern_row = _preview_row("Pattern", "SELECT", "PreviewPatternValue")
	preview_base_row = _preview_row("Base", "0", "PreviewBaseValue")
	preview_mult_row = _preview_row("Mult", "x0", "PreviewMultiplierValue")
	preview_score_row = _preview_row("Total", "0", "PreviewScoreValue")
	stack.add_child(preview_pattern_row)
	stack.add_child(preview_base_row)
	stack.add_child(preview_mult_row)
	stack.add_child(preview_score_row)

	play_button = AnimatedButtonScript.new()
	play_button.name = "PlaySetButton"
	play_button.text = "PLAY SET"
	play_button.custom_minimum_size = Vector2(88, 30)
	play_button.pressed.connect(_on_play_pressed)
	stack.add_child(play_button)

	var back_button: Button = AnimatedButtonScript.new()
	back_button.name = "MenuButton"
	back_button.text = "MENU"
	back_button.custom_minimum_size = Vector2(88, 24)
	back_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://src/scenes/main_menu/main.tscn"))
	stack.add_child(back_button)


func _build_hand_row(parent: Control) -> void:
	hand_row = HBoxContainer.new()
	hand_row.name = "HandTileRow"
	hand_row.position = Vector2(132, 292)
	hand_row.size = Vector2(472, 62)
	hand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hand_row.add_theme_constant_override("separation", 4)
	parent.add_child(hand_row)


func _build_bottom_status(parent: Control) -> void:
	var discard_panel := PanelContainer.new()
	discard_panel.name = "DiscardPanel"
	discard_panel.position = Vector2(16, 300)
	discard_panel.size = Vector2(100, 48)
	discard_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.04, 0.04, 0.038, 0.92), Color(0.58, 0.28, 0.09), 2))
	parent.add_child(discard_panel)

	var discard_stack := VBoxContainer.new()
	discard_stack.name = "DiscardStack"
	discard_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	discard_panel.add_child(discard_stack)

	var discard_title := Label.new()
	discard_title.name = "DiscardTitle"
	discard_title.text = "DISCARD"
	discard_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discard_title.add_theme_font_size_override("font_size", 10)
	discard_title.add_theme_color_override("font_color", Color(0.75, 0.84, 0.65))
	discard_stack.add_child(discard_title)

	discards_left_label = Label.new()
	discards_left_label.name = "DiscardsLeftValue"
	discards_left_label.text = "0"
	discards_left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	discards_left_label.add_theme_font_size_override("font_size", 18)
	discards_left_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.24))
	discard_stack.add_child(discards_left_label)

	hand_value_label = Label.new()
	hand_value_label.name = "HandValueLabel"
	hand_value_label.text = "HAND VALUE 0"
	hand_value_label.position = Vector2(526, 304)
	hand_value_label.size = Vector2(104, 22)
	hand_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_value_label.add_theme_font_size_override("font_size", 11)
	hand_value_label.add_theme_color_override("font_color", Color(0.78, 0.92, 0.72))
	parent.add_child(hand_value_label)


func _preview_row(label_text: String, value_text: String, value_name: String) -> PreviewRow:
	var row: PreviewRow = PreviewRowScript.new()
	row.name = value_name.replace("Value", "Row")
	row.setup(label_text, value_text, value_name)
	return row


func _refresh_hand() -> void:
	for child in hand_row.get_children():
		child.queue_free()
	selected_cards.clear()
	battle.hand.sort_in_place()
	for i in range(battle.hand.tiles.size()):
		var card: TileCard = TileCardScript.new()
		card.name = "TileCard_%02d" % i
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
	_update_play_area_echo()
	_update_preview()


func _update_play_area_echo() -> void:
	for child in play_area_tile_row.get_children():
		child.queue_free()
	for i in range(selected_cards.size()):
		var echo := Label.new()
		echo.name = "PlayedTileEcho_%02d" % i
		echo.text = selected_cards[i].tile.display_name()
		echo.custom_minimum_size = Vector2(38, 28)
		echo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		echo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		echo.add_theme_font_size_override("font_size", 13)
		echo.add_theme_color_override("font_color", Color(0.12, 0.06, 0.03))
		echo.add_theme_stylebox_override("normal", _panel_box(Color(0.95, 0.82, 0.55, 0.96), Color(0.18, 0.72, 0.34), 1))
		play_area_tile_row.add_child(echo)


func _update_preview() -> void:
	var tiles := _selected_tiles()
	_last_preview = PatternMatcher.match_pattern(tiles)
	if _last_preview.is_empty():
		var empty_text := "INVALID" if not tiles.is_empty() else "SELECT"
		preview_pattern_row.set_value(empty_text)
		preview_base_row.set_value("0")
		preview_mult_row.set_value("x0")
		preview_score_row.set_value("0")
		play_button.disabled = true
		score_burst_label.text = "SELECT A SET" if tiles.is_empty() else "INVALID SET"
		multiplier_burst_label.text = "x0 MULTIPLIER"
		hand_value_label.text = "HAND VALUE 0"
		return

	var score := Scorer.score(_last_preview)
	var english_name := _pattern_name(_last_preview)
	var final_score := int(score.get("final_score", 0))
	preview_pattern_row.set_value(english_name)
	preview_base_row.set_value(str(int(score.get("base_score", 0))))
	preview_mult_row.set_value("x%s" % _format_mult(float(score.get("pattern_mult", 0.0))))
	preview_score_row.set_value(str(final_score))
	play_button.disabled = false
	score_burst_label.text = english_name
	multiplier_burst_label.text = "x%s MULTIPLIER" % _format_mult(float(score.get("pattern_mult", 0.0)))
	hand_value_label.text = "HAND VALUE %d" % final_score
	preview_score_row.flash()


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
	_update_play_area_echo()
	_update_preview()


func _play_resolution_animation(pattern_text: String, gained: int) -> void:
	score_burst_label.text = "EPIC CHAIN!\n+" + _format_int(gained)
	score_burst_label.scale = Vector2(0.5, 0.5)
	multiplier_burst_label.text = pattern_text
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_burst_label, "scale", Vector2(1.32, 1.32), 0.16)
	tween.tween_property(score_burst_label, "modulate", Color(1.0, 0.32, 0.12), 0.08)
	tween.chain().tween_property(score_burst_label, "modulate", Color.WHITE, 0.24)
	_show_popup("+" + _format_int(gained), Color(1.0, 0.83, 0.2))
	_shake_screen()
	score_badge.pulse()


func _show_popup(message: String, color: Color) -> void:
	var popup: ScorePopup = ScorePopupScript.new()
	popup.name = "FloatingScorePopup"
	fx_layer.add_child(popup)
	popup.popup(message, Vector2(300, 170), color)


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
	round_badge.set_value("%d / %d" % [min(battle.current_turn, BattleState.MAX_TURNS), BattleState.MAX_TURNS])
	score_badge.set_value(_format_int(battle.total_score))
	target_badge.set_value(_format_int(battle.target_score))
	discards_left_label.text = str(max(BattleState.MAX_TURNS - battle.current_turn + 1, 0))


func _pattern_name(pattern: Dictionary) -> String:
	return ENGLISH_PATTERNS.get(pattern.get("id", ""), "UNKNOWN")


func _format_mult(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(value))
	return "%.1f" % value


func _format_int(value: int) -> String:
	var text := str(value)
	var out := ""
	var count := 0
	for i in range(text.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = text[i] + out
		count += 1
	return out


func _panel_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	box.shadow_size = 6
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 6
	box.content_margin_bottom = 6
	return box
