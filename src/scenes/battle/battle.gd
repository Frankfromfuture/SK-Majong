@tool
extends Control

const DuelBattleStateScript = preload("res://src/core/duel_battle_state.gd")
const MahjongTileShowcase3DScript = preload("res://src/ui/mahjong_tile_showcase_3d.gd")

const HAND_LEFT_RECT := Rect2(10, 294, 1680, 248)
const HAND_CENTER_RECT := Rect2(78, 294, 1680, 248)
const DRAW_RIGHT_RECT := Rect2(438, 294, 896, 448)
const HAND_TILE_LEFT_START := 18
const HAND_TILE_CENTER_START := 86
const HAND_TILE_SPACING := 31
const DRAW_TILE_START := 444
const DRAW_TILE_SPACING := 34
const MERGE_GHOST_SIZE := Vector2(360, 248)
const TILE_SHOWCASE_SCALE := 0.30
const DRAW_SHOWCASE_SCALE := 0.15
const MERGE_GHOST_SCALE := Vector2(0.18, 0.18)
const MERGE_GHOST_TARGET_SCALE := Vector2(0.135, 0.135)
const DRAW_INTRO_HOLD := 0.50
const DRAW_INSERT_DURATION := 0.50
const DRAW_FADE_DURATION := 0.18
const HAND_RECENTER_DURATION := 0.32
const WARLORD_DEV_SCENE := "res://characters/warlord1/dev/Warlord1DevScene.tscn"

var state: DuelBattleState
var selected := {}
var hovered := {}
var seed := 136001

var round_value: Label
var player_general_hp_value: Label
var defense_value: Label
var wall_count_value: Label
var enemy_city_defense_value: Label
var enemy_army_defense_value: Label
var enemy_attack_countdown_value: Label
var pattern_burst_label: Label
var status_value: Label
var mode_value: Label
var deploy_arrow_button: Button
var continue_button: Button
var discard_button: Button
var ultimate_button: Button
var played_pile_count_label: Label
var hand_layer: Control
var draw_layer: Control
var hand_3d_showcase: SubViewportContainer
var draw_3d_showcase: SubViewportContainer
var played_meld_layer: Control
var hits_panel: Control
var layout_guides: Control
var _is_resolving_turn := false
var _is_auto_merging_draw := false
var _draw_merge_generation := 0
var _draw_merge_elapsed := 0.0
var _draw_merge_tween: Tween
var _draw_fade_tween: Tween
var _editor_refresh_cooldown := 0.0
var _last_guide_signature := ""
var _is_building_editor_preview := false
var _bg_time := 0.0
var _bg_sparkles: Array[ColorRect] = []


func _ready() -> void:
	_start_new_run()


func _process(delta: float) -> void:
	if _is_auto_merging_draw:
		_draw_merge_elapsed += delta
		if _draw_merge_elapsed >= DRAW_INTRO_HOLD + DRAW_INSERT_DURATION + DRAW_FADE_DURATION + 0.08:
			_finish_auto_draw_merge(_draw_merge_generation)
	elif _should_auto_merge_draw():
		_start_auto_draw_merge()

	_animate_bg_sparkles(delta)

	if not Engine.is_editor_hint():
		return
	if layout_guides == null or _is_building_editor_preview:
		return
	_editor_refresh_cooldown -= delta
	if _editor_refresh_cooldown > 0.0:
		return
	var signature := _guide_signature()
	if not _last_guide_signature.is_empty() and signature != _last_guide_signature:
		_editor_refresh_cooldown = 0.08
		_build_ui()
		return
	_last_guide_signature = signature


func _start_new_run() -> void:
	state = DuelBattleStateScript.new()
	state.start_run(seed)
	selected.clear()
	hovered.clear()
	_build_ui()
	_set_status("")


func _build_ui() -> void:
	_is_building_editor_preview = Engine.is_editor_hint()
	if _is_auto_merging_draw:
		_is_auto_merging_draw = false
		_draw_merge_generation += 1
	for child in get_children():
		if child.name != "BattleLayout":
			child.queue_free()

	layout_guides = get_node_or_null("BattleLayout") as Control
	if layout_guides != null:
		layout_guides.visible = Engine.is_editor_hint()
		layout_guides.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var root := Control.new()
	root.name = "BattleRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# Add background image
	var bg_tex := TextureRect.new()
	bg_tex.name = "BattleBackgroundImage"
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	
	var bg_path := "res://assets/sprites/backgrounds/battle_bg.png"
	if FileAccess.file_exists(bg_path):
		bg_tex.texture = load(bg_path)
	
	root.add_child(bg_tex)

	_panel(root, "BattleBackground", _guide_rect("BattleBackground", Rect2(0, 0, 640, 360)), Color(0, 0, 0, 0))
	_panel(root, "LeftStatusPanel", _guide_rect("LeftStatusPanel", Rect2(8, 12, 120, 90)), Color(0, 0, 0, 0))
	_panel(root, "PlayerWarlordRail", _guide_rect("PlayerWarlordRail", Rect2(8, 108, 120, 180)), Color(0, 0, 0, 0))
	_panel(root, "RevealAreaPanel", _guide_rect("RevealAreaPanel", Rect2(136, 74, 348, 150)), Color(0, 0, 0, 0))
	_panel(root, "EnemyPanel", _guide_rect("EnemyPanel", Rect2(492, 34, 138, 86)), Color(0, 0, 0, 0))
	_panel(root, "RightSupportPanel", _guide_rect("RightSupportPanel", Rect2(492, 126, 138, 162)), Color(0, 0, 0, 0))
	_panel(root, "BottomActionPanel", _guide_rect("BottomActionPanel", Rect2(136, 230, 348, 58)), Color(0, 0, 0, 0))
	_panel(root, "HandTrayPanel", _guide_rect("HandTrayPanel", Rect2(74, 296, 494, 56)), Color(0, 0, 0, 0))

	_build_battle_header(root)
	_build_left_status(root)
	_build_future_bars(root)
	_build_reveal_area(root)
	_build_enemy_panel(root)
	_build_played_meld_ledger(root)
	_build_tile_rows(root)
	_build_played_pile(root)
	_build_tile_wall(root)
	_build_buttons(root)
	_build_bg_sparkles(root)
	_update_hud()
	if _should_auto_merge_draw():
		_start_auto_draw_merge()
	if layout_guides != null and Engine.is_editor_hint():
		layout_guides.move_to_front()
		_last_guide_signature = _guide_signature()
	_is_building_editor_preview = false


func _build_battle_header(parent: Control) -> void:
	_panel(parent, "TurnBarPanel", Rect2(240, 38, 160, 22), Color(0, 0, 0, 0))
	round_value = _label(parent, "RoundValue", "", Rect2(254, 40, 132, 18), 10, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_button(parent, "PatternToggleButton", "RULES", Rect2(582, 264, 46, 20), _on_rules_pressed)


func _build_left_status(parent: Control) -> void:
	_label(parent, "WallPanelLabel", "WALL", Rect2(16, 18, 36, 18), 8, Color(1.0, 0.86, 0.20), HORIZONTAL_ALIGNMENT_LEFT)
	wall_count_value = _label(parent, "WallCountValue", "", Rect2(54, 18, 62, 18), 13, Color(1.0, 0.86, 0.20), HORIZONTAL_ALIGNMENT_LEFT)
	_metric(parent, "PlayerGeneralHpPanel", "General HP", "", Rect2(18, 42, 96, 24))
	player_general_hp_value = _label(parent, "PlayerGeneralHpValue", "", Rect2(72, 48, 38, 12), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_metric(parent, "DefensePanel", "Army DEF", "", Rect2(18, 70, 96, 24))
	defense_value = _label(parent, "DefenseValue", "", Rect2(72, 76, 38, 12), 8, Color(0.64, 0.92, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)


func _build_future_bars(parent: Control) -> void:
	# --- Single Warlord Card (1 warlord + 2 weapons) ---
	_panel(parent, "WarlordBar", Rect2(16, 116, 104, 110), Color(0, 0, 0, 0))

	# Warlord portrait (larger, centered)
	_slot(parent, "WarlordSlot_00", Rect2(32, 122, 52, 52), "portrait")
	_label(parent, "WarlordPortrait_00", "将", Rect2(32, 122, 52, 38), 22, Color(0.72, 0.74, 0.70), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "WarlordNameLabel_00", "WARLORD", Rect2(20, 162, 80, 9), 5, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	_slot(parent, "WarlordTriggerGlow_00", Rect2(30, 120, 56, 56), "Glow")

	# Weapon slots — side by side beneath portrait
	_slot(parent, "WeaponSlot_A", Rect2(26, 177, 40, 28), "weapon")
	_label(parent, "WeaponIcon_A", "⚔", Rect2(26, 179, 40, 18), 9, Color(0.82, 0.70, 0.38), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "WeaponName_A", "WEAPON", Rect2(24, 196, 44, 7), 4, Color(0.60, 0.62, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	_slot(parent, "WeaponMarkOverlay_A", Rect2(25, 176, 42, 30), "Mark")

	_slot(parent, "WeaponSlot_B", Rect2(72, 177, 40, 28), "weapon")
	_label(parent, "WeaponIcon_B", "🛡", Rect2(72, 179, 40, 18), 9, Color(0.38, 0.70, 0.88), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "WeaponName_B", "ARMOR", Rect2(70, 196, 44, 7), 4, Color(0.60, 0.62, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	_slot(parent, "WeaponMarkOverlay_B", Rect2(71, 176, 42, 30), "Mark")

	_panel(parent, "HonorReserveBar", Rect2(500, 134, 122, 74), Color(0, 0, 0, 0))
	_label(parent, "HonorReserveTitle", "HONORS 2.0", Rect2(506, 138, 110, 12), 8, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	var honors := ["东", "南", "西", "北", "中", "发", "白"]
	for i in range(honors.size()):
		var x := 508 + (i % 4) * 27
		var y := 156 + int(i / 4) * 21
		_slot(parent, "BuffSlot_%02d" % i, Rect2(x, y, 20, 16), "2.0")
		_label(parent, "BuffValueLabel_%02d" % i, honors[i], Rect2(x, y, 20, 16), 8, Color(0.62, 0.65, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
		_label(parent, "BuffIcon_Reserved_%02d" % i, "OFF", Rect2(x - 1, y + 15, 22, 7), 4, Color(0.45, 0.48, 0.45), HORIZONTAL_ALIGNMENT_CENTER)

	_panel(parent, "ConsumableBar", Rect2(500, 220, 122, 34), Color(0, 0, 0, 0))
	_label(parent, "ConsumableBarTitle", "V1.0", Rect2(506, 224, 110, 12), 8, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "ConsumableCountLabel_00", "万=DEF  条=Melee  饼=Ranged", Rect2(504, 238, 116, 10), 5, Color(0.70, 0.74, 0.70), HORIZONTAL_ALIGNMENT_CENTER)


func _build_reveal_area(parent: Control) -> void:
	_label(parent, "RevealAreaTitle", "BATTLE", Rect2(146, 82, 328, 16), 13, Color.CYAN, HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "PlayerConditionPanel", Rect2(146, 100, 92, 16), Color(0, 0, 0, 0))
	_label(parent, "PlayerConditionValue", "Army %d" % state.player_army_defense, Rect2(150, 101, 84, 14), 7, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "EnemyConditionPanel", Rect2(382, 100, 92, 16), Color(0, 0, 0, 0))
	_label(parent, "EnemyConditionValue", "Army %d" % state.enemy_army_defense, Rect2(386, 101, 84, 14), 7, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "AllyUnit_00", Rect2(164, 146, 32, 28), Color(0, 0, 0, 0))
	_label(parent, "AllyUnitLabel_00", "P1", Rect2(164, 147, 32, 18), 10, Color(0.68, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "AllyUnit_01", Rect2(218, 126, 32, 28), Color(0, 0, 0, 0))
	_label(parent, "AllyUnitLabel_01", "P2", Rect2(218, 127, 32, 18), 10, Color(0.68, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "AllyUnit_02", Rect2(272, 146, 32, 28), Color(0, 0, 0, 0))
	_label(parent, "AllyUnitLabel_02", "P3", Rect2(272, 147, 32, 18), 10, Color(0.68, 1.0, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "EnemyWarlordUnit", Rect2(404, 134, 42, 34), Color(0, 0, 0, 0))
	_label(parent, "EnemyUnitSprite", "EN", Rect2(404, 136, 42, 22), 11, Color(1.0, 0.48, 0.36), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "EnemyIntentBox", Rect2(370, 174, 104, 34), Color(0, 0, 0, 0))
	_label(parent, "EnemyIntentBoxValue", "ATK %d\nCD %d" % [state.enemy_attack, state.enemy_attack_countdown], Rect2(376, 176, 92, 28), 9, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	pattern_burst_label = _label(parent, "PatternBurstLabel", "", Rect2(166, 114, 288, 28), 21, Color(0.62, 0.65, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "ConcealedMeldHintPanel", Rect2(146, 208, 78, 14), Color(0, 0, 0, 0))
	_label(parent, "ConcealedMeldHintValue", "Dark %d" % _concealed_hint_count(), Rect2(150, 208, 70, 12), 6, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "PairCandidateHintPanel", Rect2(230, 208, 66, 14), Color(0, 0, 0, 0))
	_label(parent, "PairCandidateHintValue", "Pairs %d" % _pair_hint_count(), Rect2(234, 208, 58, 12), 6, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "ShantenBadge", Rect2(302, 208, 56, 14), Color(0, 0, 0, 0))
	_label(parent, "ShantenValue", "Hu" if state.can_ultimate_win() else "Build", Rect2(306, 208, 48, 12), 6, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	_panel(parent, "WinMultiplierBadge", Rect2(364, 208, 62, 14), Color(0, 0, 0, 0))
	_label(parent, "WinMultiplierValue", "x%.2f" % state.current_win_multiplier(), Rect2(368, 208, 54, 12), 6, Color(1.0, 0.42, 0.32), HORIZONTAL_ALIGNMENT_CENTER)
	mode_value = _label(parent, "ModeValue", "", Rect2(146, 232, 328, 12), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	status_value = _label(parent, "StatusValue", "", Rect2(146, 244, 328, 10), 8, Color(0.78, 1.0, 0.76), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "HandLabel", "HAND", Rect2(16, 286, 80, 10), 8, Color.CYAN)


func _build_enemy_panel(parent: Control) -> void:
	_label(parent, "EnemyNameLabel", "ENEMY WARLORD", Rect2(500, 42, 122, 16), 10, Color(1.0, 0.72, 0.18), HORIZONTAL_ALIGNMENT_CENTER)
	_metric(parent, "EnemyCityDefensePanel", "City DEF", "", Rect2(502, 62, 118, 24))
	enemy_city_defense_value = _label(parent, "EnemyCityDefenseValue", "", Rect2(574, 68, 42, 12), 8, Color(1.0, 0.42, 0.32), HORIZONTAL_ALIGNMENT_RIGHT)
	_metric(parent, "EnemyAttackCountdownPanel", "Intent", "", Rect2(502, 88, 118, 24))
	enemy_attack_countdown_value = _label(parent, "EnemyAttackCountdownValue", "", Rect2(574, 94, 42, 12), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
	_label(parent, "EnemyIntentLabel", "Army DEF", Rect2(500, 116, 58, 10), 6, Color(0.80, 0.82, 0.78), HORIZONTAL_ALIGNMENT_CENTER)
	enemy_army_defense_value = _label(parent, "EnemyArmyDefenseValue", "", Rect2(558, 116, 58, 10), 7, Color(0.64, 0.92, 1.0), HORIZONTAL_ALIGNMENT_RIGHT)
	_label(parent, "EnemyAttackValue", "ATK %d" % state.enemy_attack, Rect2(500, 126, 122, 12), 8, Color(1.0, 0.42, 0.32), HORIZONTAL_ALIGNMENT_CENTER)
	_label(parent, "EnemyDefenseMirrorValue", "", Rect2(500, 138, 122, 10), 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _build_played_meld_ledger(parent: Control) -> void:
	_panel(parent, "OpenMeldLedgerPanel", Rect2(210, 252, 116, 32), Color(0, 0, 0, 0))
	_label(parent, "OpenMeldLedgerTitle", "BATTLE MOVES", Rect2(216, 254, 104, 10), 7, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	played_meld_layer = Control.new()
	played_meld_layer.name = "OpenMeldLedgerList"
	parent.add_child(played_meld_layer)

	var rows: int = min(2, state.open_melds.size())
	for i in range(rows):
		var meld: Dictionary = state.open_melds[state.open_melds.size() - rows + i]
		var effect := _effect_label(meld)
		_label(played_meld_layer, "OpenMeldRow_%02d" % i, "%s  %s" % [meld.get("name", "Meld"), effect], Rect2(216, 264 + i * 9, 104, 8), 5, Color.WHITE)


func _build_tile_rows(parent: Control) -> void:
	var draw_rect := _guide_rect("DrawTile3DShowcase", DRAW_RIGHT_RECT)
	draw_3d_showcase = MahjongTileShowcase3DScript.new()
	draw_3d_showcase.name = "DrawTile3DShowcase"
	draw_3d_showcase.position = draw_rect.position
	draw_3d_showcase.size = draw_rect.size
	draw_3d_showcase.scale = Vector2(DRAW_SHOWCASE_SCALE, DRAW_SHOWCASE_SCALE)
	draw_3d_showcase.visible = _should_show_draw_tiles()
	parent.add_child(draw_3d_showcase)
	draw_3d_showcase.connect("tile_hovered", _on_tile_hovered)
	draw_3d_showcase.connect("tile_pressed", _on_tile_pressed)
	draw_3d_showcase.setup_tiles(state.drawn, selected, hovered, DuelBattleState.TileZone.DRAW)

	draw_layer = Control.new()
	draw_layer.name = "DrawTileLayer"
	draw_layer.position = Vector2.ZERO
	draw_layer.visible = _should_show_draw_tiles()
	parent.add_child(draw_layer)
	for i in range(state.drawn.size()):
		var rect := Rect2(DRAW_TILE_START + i * DRAW_TILE_SPACING, 304, 28, 40)
		_tile_button(draw_layer, DuelBattleState.TileZone.DRAW, i, state.drawn[i], rect)

	var hand_rect := _hand_showcase_rect()
	hand_3d_showcase = MahjongTileShowcase3DScript.new()
	hand_3d_showcase.name = "HandTile3DShowcase"
	hand_3d_showcase.position = hand_rect.position
	hand_3d_showcase.size = hand_rect.size
	hand_3d_showcase.scale = Vector2(TILE_SHOWCASE_SCALE, TILE_SHOWCASE_SCALE)
	parent.add_child(hand_3d_showcase)
	hand_3d_showcase.connect("tile_hovered", _on_tile_hovered)
	hand_3d_showcase.connect("tile_pressed", _on_tile_pressed)
	hand_3d_showcase.setup_tiles(state.hand.tiles, selected, hovered, DuelBattleState.TileZone.HAND)

	hand_layer = Control.new()
	hand_layer.name = "HandTileLayer"
	hand_layer.position = Vector2.ZERO
	parent.add_child(hand_layer)
	var hand_start := HAND_TILE_CENTER_START
	for i in range(state.hand.tiles.size()):
		var rect := Rect2(hand_start + i * HAND_TILE_SPACING, 304, 30, 42)
		_tile_button(hand_layer, DuelBattleState.TileZone.HAND, i, state.hand.tiles[i], rect)


func _build_tile_wall(parent: Control) -> void:
	var wall_rect := _guide_rect("TileWallPanel", Rect2(574, 296, 58, 56))
	_panel(parent, "TileWallPanel", wall_rect, Color(0, 0, 0, 0))
	_label(parent, "TileWallLabel", "WALL", Rect2(578, 299, 50, 10), 7, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(10):
		var col := i % 5
		var row := int(i / 5)
		_panel(parent, "TileWallTile_%02d" % i, Rect2(580 + col * 9, 314 + row * 13, 8, 12), Color(0.78, 0.70, 0.52))
	_label(parent, "TileWallCount", "%d" % state.remaining_deck(), Rect2(578, 338, 50, 10), 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _build_played_pile(parent: Control) -> void:
	var pile_rect := _guide_rect("PlayedPilePanel", Rect2(8, 296, 58, 56))
	_panel(parent, "PlayedPilePanel", pile_rect, Color(0, 0, 0, 0))
	_label(parent, "PlayedPileLabel", "PILE", Rect2(12, 299, 50, 10), 7, Color(1.0, 0.86, 0.22), HORIZONTAL_ALIGNMENT_CENTER)
	for i in range(10):
		var col := i % 5
		var row := int(i / 5)
		_panel(parent, "PlayedPileTile_%02d" % i, Rect2(14 + col * 9, 314 + row * 13, 8, 12), Color(0.78, 0.70, 0.52))
	played_pile_count_label = _label(parent, "PlayedPileCount", "0", Rect2(12, 338, 50, 10), 6, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	played_pile_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pile_click := Button.new()
	pile_click.name = "PlayedPileButton"
	pile_click.position = pile_rect.position
	pile_click.size = pile_rect.size
	pile_click.focus_mode = Control.FOCUS_NONE
	pile_click.text = ""
	pile_click.tooltip_text = "Played pile"
	var empty_box := _box(Color(1, 1, 1, 0), Color(1, 1, 1, 0), 0, 0)
	pile_click.add_theme_stylebox_override("normal", empty_box)
	pile_click.add_theme_stylebox_override("hover", empty_box)
	pile_click.add_theme_stylebox_override("pressed", empty_box)
	pile_click.add_theme_stylebox_override("focus", empty_box)
	pile_click.pressed.connect(_on_hits_pressed)
	parent.add_child(pile_click)


func _should_show_draw_tiles() -> bool:
	return state != null and state.drawn.size() > 0 and not _is_resolving_turn


func _should_auto_merge_draw() -> bool:
	return state != null and state.drawn.size() > 0 and not _is_auto_merging_draw


func _hand_showcase_rect() -> Rect2:
	var guide := _guide_rect("HandTile3DShowcase", HAND_CENTER_RECT)
	return Rect2(HAND_CENTER_RECT.position, guide.size)


func _build_buttons(parent: Control) -> void:
	continue_button = _button(parent, "ContinueButton", "PASS", Rect2(146, 260, 58, 20), _on_continue_pressed)
	discard_button = _button(parent, "DiscardButton", "DISCARD", Rect2(206, 260, 58, 20), _on_discard_pressed)
	deploy_arrow_button = _button(parent, "DeployArrowButton", "PLAY ↑", Rect2(268, 280, 84, 20), _on_play_tiles_pressed)
	deploy_arrow_button.visible = false
	discard_button.visible = false
	_button(parent, "SortBySuitButton", "SORT SUIT", _guide_rect("SortBySuitButton", Rect2(394, 260, 64, 20)), _on_sort_suit_pressed)
	ultimate_button = _button(parent, "UltimateWinButton", "ASSAULT", _guide_rect("UltimateWinButton", Rect2(462, 260, 70, 20)), _on_ultimate_pressed)
	_button(parent, "HitsButton", "HITS", _guide_rect("HitsButton", Rect2(536, 260, 42, 20)), _on_hits_pressed)
	_button(parent, "WarlordDevButton", "Warlord Dev", Rect2(490, 8, 88, 20), _on_warlord_dev_pressed)
	_button(parent, "MainMenuButton", "MENU", _guide_rect("MainMenuButton", Rect2(582, 8, 46, 20)), func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/main_menu/main.tscn")
	)


func _tile_button(parent: Control, zone: int, index: int, tile: Tile, rect: Rect2) -> Button:
	var node_name := "%sTile_%02d" % ["Draw" if zone == DuelBattleState.TileZone.DRAW else "Hand", index]
	rect = _guide_rect(node_name, rect, "tile")
	var button := Button.new()
	button.name = node_name
	button.text = ""
	button.tooltip_text = ""
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_theme_font_size_override("font_size", 9 if zone == DuelBattleState.TileZone.DRAW else 7)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.0))
	var empty_box := _box(Color(1.0, 1.0, 1.0, 0.0), Color(1.0, 1.0, 1.0, 0.0), 0, 0)
	button.add_theme_stylebox_override("normal", empty_box)
	button.add_theme_stylebox_override("hover", empty_box)
	button.add_theme_stylebox_override("pressed", empty_box)
	button.add_theme_stylebox_override("focus", empty_box)
	button.add_theme_stylebox_override("disabled", empty_box)
	button.pivot_offset = rect.size / 2.0
	parent.add_child(button)
	return button


func _on_tile_hovered(zone: int, index: int, is_hovered: bool) -> void:
	var key := _selection_key(zone, index)
	if is_hovered:
		hovered[key] = true
	else:
		hovered.erase(key)
	if zone == DuelBattleState.TileZone.HAND and hand_3d_showcase != null:
		hand_3d_showcase.call("set_tile_hovered", zone, index, is_hovered)
	elif zone == DuelBattleState.TileZone.DRAW and draw_3d_showcase != null:
		draw_3d_showcase.call("set_tile_hovered", zone, index, is_hovered)


func _on_tile_pressed(zone: int, index: int) -> void:
	if state.is_complete or state.pending_hu_choice or _is_resolving_turn or _is_auto_merging_draw:
		return
	var key := _selection_key(zone, index)
	if selected.has(key):
		selected.erase(key)
	else:
		selected[key] = {"zone": zone, "index": index}
	hovered.erase(key)
	_rebuild_after_change()


func _on_play_tiles_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	var selections := selected.values()
	var preview := state.preview_play(selections)
	if not bool(preview.get("valid", false)):
		_set_status(_reason_to_text(str(preview.get("reason", "invalid_selection"))))
		return
	_is_resolving_turn = true
	_update_hud()
	var result := state.play_tiles(selections)
	selected.clear()
	_is_resolving_turn = false
	if not bool(result.get("valid", false)):
		_build_ui()
		_set_status(_reason_to_text(str(result.get("reason", "invalid_selection"))))
		return
	_build_ui()
	_set_status(str(result.get("event", "Tiles played")))


func _on_continue_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	_is_resolving_turn = true
	var result := state.decline_ultimate_win() if state.pending_hu_choice else state.play_tiles([])
	selected.clear()
	_is_resolving_turn = false
	if not bool(result.get("valid", false)):
		_build_ui()
		_set_status(_reason_to_text(str(result.get("reason", "invalid_selection"))))
		return
	_build_ui()
	_set_status(str(result.get("event", "Continue")))


func _on_discard_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	var result := state.discard_selected(selected.values())
	selected.clear()
	if not bool(result.get("valid", false)):
		_build_ui()
		_set_status(_reason_to_text(str(result.get("reason", "invalid_selection"))))
		return
	_build_ui()
	_set_status(str(result.get("event", "Discarded")))


func _on_ultimate_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	var result := state.ultimate_win()
	if not bool(result.get("valid", false)):
		_set_status(_reason_to_text(str(result.get("reason", "not_ready"))))
		return
	selected.clear()
	_build_ui()
	_set_status(str(result.get("event", "Ultimate Win")))


func _on_finish_pressed() -> void:
	var scene := preload("res://src/scenes/game_over/game_over.tscn").instantiate()
	scene.setup(state.result == DuelBattleState.BattleResult.WIN, state.turn_number)
	get_tree().root.add_child(scene)
	get_tree().current_scene = scene
	queue_free()


func _on_sort_suit_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	state.hand.sort_in_place()
	selected.clear()
	_rebuild_after_change()
	_set_status("Hand sorted by suit")


func _on_sort_rank_pressed() -> void:
	if _is_resolving_turn or _is_auto_merging_draw:
		return
	state.hand.tiles.sort_custom(func(a: Tile, b: Tile) -> bool:
		if a.rank != b.rank:
			return a.rank < b.rank
		return a.suit < b.suit
	)
	selected.clear()
	_rebuild_after_change()
	_set_status("Hand sorted by rank")


func _on_rules_pressed() -> void:
	get_tree().change_scene_to_file("res://src/scenes/rules/rules.tscn")


func _on_warlord_dev_pressed() -> void:
	get_tree().change_scene_to_file(WARLORD_DEV_SCENE)


func _on_hits_pressed() -> void:
	_show_hits_panel()


func _show_hits_panel() -> void:
	var root := get_node_or_null("BattleRoot") as Control
	if root == null:
		root = self
	var existing := root.get_node_or_null("HitsStatsPanel")
	if existing != null:
		existing.queue_free()
		return

	hits_panel = Panel.new()
	hits_panel.name = "HitsStatsPanel"
	hits_panel.position = Vector2(346, 82)
	hits_panel.size = Vector2(220, 174)
	hits_panel.add_theme_stylebox_override("panel", _box(Color(0.045, 0.055, 0.052, 0.97), Color(0.9, 0.58, 0.18), 1, 4))
	root.add_child(hits_panel)
	hits_panel.move_to_front()

	_label(hits_panel, "HitsStatsTitle", "PLAYED PILE", Rect2(10, 8, 160, 16), 12, Color(1.0, 0.86, 0.22))
	_button(hits_panel, "HitsCloseButton", "X", Rect2(190, 8, 20, 18), _close_hits_panel)

	var totals := _hits_totals()
	_label(hits_panel, "HitsAttackTotal", "M %d" % int(totals.get("melee", 0)), Rect2(12, 30, 62, 14), 8, Color(1.0, 0.42, 0.32))
	_label(hits_panel, "HitsDefenseTotal", "R %d" % int(totals.get("ranged", 0)), Rect2(78, 30, 62, 14), 8, Color(1.0, 0.72, 0.32))
	_label(hits_panel, "HitsArmyDefenseTotal", "D %d" % int(totals.get("army_defense", 0)), Rect2(144, 30, 62, 14), 8, Color(0.64, 0.92, 1.0))

	var rows := _hits_rows()
	if rows.is_empty():
		_label(hits_panel, "HitsEmptyLabel", "No played hits yet", Rect2(12, 58, 190, 18), 8, Color(0.70, 0.74, 0.70), HORIZONTAL_ALIGNMENT_CENTER)
		return
	var row_count: int = min(rows.size(), 7)
	for i in range(row_count):
		var row: Dictionary = rows[rows.size() - row_count + i]
		var y := 54 + i * 16
		var text := "%s  %s" % [str(row.get("kind", "")), str(row.get("tiles", ""))]
		_label(hits_panel, "HitsRow_%02d" % i, text, Rect2(12, y, 124, 14), 6, Color.WHITE)
		_label(hits_panel, "HitsRowValues_%02d" % i, "M%d R%d D%d" % [
			int(row.get("melee", 0)),
			int(row.get("ranged", 0)),
			int(row.get("army_defense", 0)),
		], Rect2(138, y, 70, 14), 6, Color(0.78, 0.92, 0.78), HORIZONTAL_ALIGNMENT_RIGHT)


func _close_hits_panel() -> void:
	if hits_panel != null and is_instance_valid(hits_panel):
		hits_panel.queue_free()
	hits_panel = null


func _on_new_run_pressed() -> void:
	seed += 1
	_start_new_run()


func _rebuild_after_change() -> void:
	var current_status := status_value.text if status_value != null else ""
	_build_ui()
	_set_status(current_status)


func _start_auto_draw_merge() -> void:
	_is_auto_merging_draw = true
	_draw_merge_elapsed = 0.0
	_draw_merge_generation += 1
	if DisplayServer.get_name() == "headless":
		_finish_auto_draw_merge(_draw_merge_generation)
		return
	_animate_draw_into_hand(_draw_merge_generation)


func _finish_auto_draw_merge(generation: int) -> void:
	if generation != _draw_merge_generation:
		return
	state.accept_drawn_into_hand()
	_is_auto_merging_draw = false
	_build_ui()
	_set_status(state.action_prompt())


func _animate_draw_into_hand(generation: int) -> void:
	if draw_3d_showcase == null or hand_3d_showcase == null:
		return
	var drawn_tiles := state.drawn.duplicate()
	var merge_ghosts := []
	if draw_3d_showcase != null:
		draw_3d_showcase.modulate.a = 1.0
	await get_tree().create_timer(DRAW_INTRO_HOLD).timeout
	if generation != _draw_merge_generation or not _is_auto_merging_draw:
		_clear_merge_ghosts(merge_ghosts)
		return
	if not is_instance_valid(draw_3d_showcase) or not is_instance_valid(hand_3d_showcase):
		_clear_merge_ghosts(merge_ghosts)
		return
	var merge_parent := get_node_or_null("BattleRoot") as Control
	if merge_parent == null:
		merge_parent = self
	if not is_instance_valid(merge_parent):
		return
	merge_ghosts = _build_merge_ghosts(merge_parent, drawn_tiles)
	draw_3d_showcase.modulate.a = 0.0
	if is_instance_valid(draw_layer):
		draw_layer.modulate.a = 0.0
	var target_positions := _draw_merge_target_positions(drawn_tiles)
	_draw_merge_tween = create_tween()
	_draw_merge_tween.set_parallel(true)
	_draw_merge_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	for i in range(merge_ghosts.size()):
		var ghost_node = merge_ghosts[i]
		if not is_instance_valid(ghost_node):
			continue
		var ghost := ghost_node as Control
		var target: Vector2 = target_positions.get(i, HAND_LEFT_RECT.position)
		var mid := Vector2(
			lerp(ghost.position.x, target.x, 0.48),
			min(ghost.position.y, target.y) - 54.0 - float(i) * 12.0
		)
		_draw_merge_tween.tween_property(ghost, "position", mid, DRAW_INSERT_DURATION * 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_draw_merge_tween.tween_property(ghost, "position", target, DRAW_INSERT_DURATION * 0.55).set_delay(DRAW_INSERT_DURATION * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		_draw_merge_tween.tween_property(ghost, "scale", MERGE_GHOST_TARGET_SCALE, DRAW_INSERT_DURATION)
	await get_tree().create_timer(DRAW_INSERT_DURATION + 0.04).timeout
	if generation != _draw_merge_generation or not _is_auto_merging_draw:
		_clear_merge_ghosts(merge_ghosts)
		return

	_draw_fade_tween = create_tween()
	_draw_fade_tween.set_parallel(true)
	if is_instance_valid(draw_3d_showcase):
		_draw_fade_tween.tween_property(draw_3d_showcase, "modulate:a", 0.0, DRAW_FADE_DURATION)
	if is_instance_valid(draw_layer):
		_draw_fade_tween.tween_property(draw_layer, "modulate:a", 0.0, DRAW_FADE_DURATION)
	for ghost_node in merge_ghosts:
		if is_instance_valid(ghost_node):
			_draw_fade_tween.tween_property(ghost_node, "modulate:a", 0.0, DRAW_FADE_DURATION)
	await get_tree().create_timer(DRAW_FADE_DURATION + 0.04).timeout
	_clear_merge_ghosts(merge_ghosts)


func _clear_merge_ghosts(merge_ghosts: Array) -> void:
	for ghost in merge_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()


func _build_merge_ghosts(parent: Control, drawn_tiles: Array) -> Array:
	var ghosts := []
	for i in range(drawn_tiles.size()):
		var ghost: Control = MahjongTileShowcase3DScript.new()
		ghost.name = "DrawMergeGhost_%02d" % i
		ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ghost.position = Vector2(DRAW_TILE_START + i * DRAW_TILE_SPACING - 16, 292)
		ghost.size = MERGE_GHOST_SIZE
		ghost.scale = MERGE_GHOST_SCALE
		ghost.modulate = Color(1.0, 1.0, 1.0, 0.96)
		parent.add_child(ghost)
		ghost.call("setup_tiles", [drawn_tiles[i]], {}, {}, DuelBattleState.TileZone.DRAW)
		ghosts.append(ghost)
	return ghosts


func _draw_merge_target_positions(drawn_tiles: Array) -> Dictionary:
	var entries := []
	for tile in state.hand.tiles:
		entries.append({"tile": tile, "draw_index": -1})
	for i in range(drawn_tiles.size()):
		entries.append({"tile": drawn_tiles[i], "draw_index": i})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var tile_a: Tile = a["tile"]
		var tile_b: Tile = b["tile"]
		var compare := tile_a.compare_to(tile_b)
		if compare != 0:
			return compare < 0
		return int(a["draw_index"]) < int(b["draw_index"])
	)

	var targets := {}
	for sorted_index in range(entries.size()):
		var draw_index := int(entries[sorted_index]["draw_index"])
		if draw_index >= 0:
			targets[draw_index] = Vector2(HAND_TILE_CENTER_START + sorted_index * HAND_TILE_SPACING - 16, 292)
	return targets


func _hits_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for play in state.played_sets:
		var play_id := str(play.get("id", ""))
		if play_id == "pass":
			continue
		var stats := _effect_stats(play.get("effects", []) as Array)
		var tile_names := play.get("tiles", []) as Array
		rows.append({
			"kind": "MOVE" if play_id == "sequence" or play_id == "triplet" or play_id == "kan" else "PLAY",
			"tiles": " ".join(tile_names),
			"melee": int(stats.get("melee", 0)),
			"ranged": int(stats.get("ranged", 0)),
			"army_defense": int(stats.get("army_defense", 0)),
		})
	return rows


func _hits_totals() -> Dictionary:
	var totals := {"melee": 0, "ranged": 0, "army_defense": 0}
	for row in _hits_rows():
		totals["melee"] = int(totals.get("melee", 0)) + int(row.get("melee", 0))
		totals["ranged"] = int(totals.get("ranged", 0)) + int(row.get("ranged", 0))
		totals["army_defense"] = int(totals.get("army_defense", 0)) + int(row.get("army_defense", 0))
	return totals


func _played_tile_count() -> int:
	var total := 0
	for play in state.played_sets:
		total += (play.get("tiles", []) as Array).size()
	return total


func _effect_stats(effects: Array) -> Dictionary:
	var stats := {"melee": 0, "ranged": 0, "army_defense": 0}
	for effect in effects:
		var effect_type := str(effect.get("type", "none"))
		if not stats.has(effect_type):
			continue
		stats[effect_type] = int(stats.get(effect_type, 0)) + int(effect.get("value", 0))
	return stats


func _effect_label(play: Dictionary) -> String:
	var effects := play.get("effects", []) as Array
	if effects.is_empty():
		return "No effect"
	var effect: Dictionary = effects[0]
	match str(effect.get("type", "none")):
		"melee":
			return "M %d" % int(effect.get("value", 0))
		"ranged":
			return "R %d" % int(effect.get("value", 0))
		"army_defense":
			return "DEF %d" % int(effect.get("value", 0))
	return "No effect"


func _update_hud() -> void:
	round_value.text = "Turn %d" % state.turn_number
	player_general_hp_value.text = "%d" % state.player_general_hp
	defense_value.text = "%d" % state.player_army_defense
	wall_count_value.text = "%d" % state.remaining_deck()
	enemy_city_defense_value.text = "%d" % state.enemy_city_defense
	if enemy_army_defense_value != null:
		enemy_army_defense_value.text = "%d" % state.enemy_army_defense
	enemy_attack_countdown_value.text = "%d turns" % state.enemy_attack_countdown

	var mirror := find_child("EnemyDefenseMirrorValue", true, false) as Label
	if mirror != null:
		mirror.text = "City %d / Army %d" % [state.enemy_city_defense, state.enemy_army_defense]

	mode_value.text = state.action_prompt()
	var selection_count := selected.size()
	var can_discard := not _is_auto_merging_draw and not _is_resolving_turn and not state.is_complete and state.is_discard_required() and selection_count > 0 and selection_count <= state.required_discard_count()
	var can_deploy := false
	if not _is_auto_merging_draw and not _is_resolving_turn and not state.is_complete and not state.pending_hu_choice and not state.is_discard_required() and selection_count > 0:
		var preview := state.preview_play(selected.values())
		can_deploy = bool(preview.get("valid", false))
	deploy_arrow_button.visible = can_deploy
	deploy_arrow_button.disabled = not can_deploy
	discard_button.visible = state.is_discard_required()
	discard_button.disabled = not can_discard
	continue_button.text = "SKIP HU" if state.pending_hu_choice else "PASS"
	continue_button.disabled = _is_auto_merging_draw or _is_resolving_turn or state.is_complete or state.is_discard_required() or selection_count > 0
	if played_pile_count_label != null:
		played_pile_count_label.text = "%d" % _played_tile_count()
	ultimate_button.disabled = _is_auto_merging_draw or _is_resolving_turn or state.is_complete or not state.pending_hu_choice or not state.can_ultimate_win()

	if state.result == DuelBattleState.BattleResult.WIN:
		pattern_burst_label.text = "VICTORY"
		pattern_burst_label.add_theme_color_override("font_color", Color.YELLOW)
	elif state.result == DuelBattleState.BattleResult.LOSE:
		pattern_burst_label.text = "DEFEAT"
		pattern_burst_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.24))
	elif state.pending_hu_choice:
		pattern_burst_label.text = "TOTAL ASSAULT READY"
		pattern_burst_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22))
	elif state.is_discard_required():
		pattern_burst_label.text = "DISCARD TO 14"
		pattern_burst_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.18))
	elif state.can_ultimate_win():
		pattern_burst_label.text = "HU SHAPE"
		pattern_burst_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.22))
	else:
		pattern_burst_label.text = "BUILD MELDS"
		pattern_burst_label.add_theme_color_override("font_color", Color(0.62, 0.65, 0.62))


func _set_status(text: String) -> void:
	if status_value != null:
		status_value.text = text


func _selection_key(zone: int, index: int) -> String:
	return "%d:%d" % [zone, index]


func _reason_to_text(reason: String) -> String:
	match reason:
		"battle_complete":
			return "Battle is already complete"
		"play_one_to_three":
			return "Select 1 to 3 tiles to play"
		"play_zero_to_three_or_kan":
			return "Play 0-3 tiles, or 4 identical tiles as Kan"
		"kan_requires_four_identical":
			return "Kan needs four identical tiles"
		"discard_required":
			return "Discard down to 14 before acting"
		"discard_count":
			return "Select the required number of discards"
		"discard_from_hand":
			return "Discard from hand tiles"
		"resolve_hu_choice":
			return "Choose Assault or Skip Hu"
		"not_pending_hu":
			return "Total Assault is only available after a Hu check"
		"not_a_meld":
			return "Selected tiles are not a sequence, triplet, or kan"
		"not_ready":
			return "Ultimate Win needs open/concealed melds plus a pair"
		"invalid_selection":
			return "Selection is no longer valid"
	return reason


func _concealed_hint_count() -> int:
	var breakdown := state.get_win_breakdown()
	if breakdown.is_empty():
		return 0
	return int((breakdown.get("concealed_melds", []) as Array).size())


func _pair_hint_count() -> int:
	var counts := {}
	for tile in state.hand.tiles:
		counts[tile.key()] = int(counts.get(tile.key(), 0)) + 1
	var pairs := 0
	for count in counts.values():
		if int(count) >= 2:
			pairs += 1
	return pairs


func _metric(parent: Control, node_name: String, label_text: String, value_text: String, rect: Rect2) -> void:
	rect = _guide_rect(node_name, rect, "panel")
	_panel(parent, node_name, rect, Color(0, 0, 0, 0))
	_label(parent, "%sLabel" % node_name, label_text, Rect2(rect.position.x, rect.position.y + 3, rect.size.x, 10), 7, Color(0.62, 0.65, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	if not value_text.is_empty():
		_label(parent, "%sValueText" % node_name, value_text, Rect2(rect.position.x, rect.position.y + 15, rect.size.x, 12), 8, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)


func _slot(parent: Control, node_name: String, rect: Rect2, _unused_slot_text: String) -> void:
	rect = _guide_rect(node_name, rect, "slot")
	_panel(parent, node_name, rect, Color(0, 0, 0, 0))


func _button(parent: Control, node_name: String, text: String, rect: Rect2, callback: Callable) -> Button:
	rect = _guide_rect(node_name, rect, "button")
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


func _panel(parent: Control, node_name: String, rect: Rect2, color: Color):
	rect = _guide_rect(node_name, rect, "panel")
	# Pure layout mode: transparent placeholders are skipped entirely.
	if color.a <= 0.001:
		return null
	var panel := Panel.new()
	panel.name = node_name
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _box(color, Color(0.20, 0.12, 0.06), 1, 4))
	parent.add_child(panel)
	return panel


func _label(parent: Control, node_name: String, text: String, rect: Rect2, font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	rect = _guide_rect(node_name, rect, "label")
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


func _guide_rect(node_name: String, fallback: Rect2, guide_type := "panel") -> Rect2:
	if layout_guides == null:
		return fallback
	var guide := layout_guides.get_node_or_null("Guide_%s" % node_name) as Control
	if guide == null:
		guide = _create_editor_guide(node_name, fallback, guide_type)
		if guide == null:
			return fallback
	return Rect2(guide.position, guide.size)


func _create_editor_guide(node_name: String, rect: Rect2, guide_type: String) -> Control:
	if not Engine.is_editor_hint() or layout_guides == null:
		return null
	var guide := ColorRect.new()
	guide.name = "Guide_%s" % node_name
	guide.position = rect.position
	guide.size = rect.size
	guide.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match guide_type:
		"label":
			guide.color = Color(1.0, 1.0, 1.0, 0.10)
		"button":
			guide.color = Color(1.0, 0.20, 0.10, 0.22)
		"tile":
			guide.color = Color(0.0, 1.0, 1.0, 0.20)
		"slot":
			guide.color = Color(0.8, 0.8, 0.8, 0.16)
		_:
			guide.color = Color(0.20, 0.70, 1.0, 0.14)
	layout_guides.add_child(guide)
	var scene_root := get_tree().edited_scene_root if get_tree() != null else null
	if scene_root != null:
		guide.owner = scene_root
	return guide


func _guide_signature() -> String:
	if layout_guides == null:
		return ""
	var parts: Array[String] = []
	for child in layout_guides.get_children():
		var control := child as Control
		if control == null:
			continue
		parts.append("%s:%.2f,%.2f,%.2f,%.2f" % [
			control.name,
			control.position.x,
			control.position.y,
			control.size.x,
			control.size.y,
		])
	parts.sort()
	return "|".join(parts)


func _build_bg_sparkles(parent: Control) -> void:
	_bg_sparkles.clear()
	var sparkle_layer := Control.new()
	sparkle_layer.name = "BackgroundSparkleLayer"
	sparkle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	sparkle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(sparkle_layer)
	
	# Move behind UI but in front of background image
	parent.move_child(sparkle_layer, 1)

	for i in range(15):
		var spark := ColorRect.new()
		spark.name = "BgSpark_%02d" % i
		spark.position = Vector2(randf() * 640.0, randf() * 360.0)
		spark.size = Vector2(1.5, 1.5)
		# Warm sunset colors or cool mountain colors
		spark.color = Color(1.0, 0.8, 0.3, 0.6) if i % 2 == 0 else Color(0.6, 0.9, 1.0, 0.4)
		sparkle_layer.add_child(spark)
		_bg_sparkles.append(spark)


func _animate_bg_sparkles(delta: float) -> void:
	_bg_time += delta
	for i in range(_bg_sparkles.size()):
		var spark := _bg_sparkles[i]
		if not is_instance_valid(spark): continue
		
		# Gentle drift
		spark.position.x += (5.0 + (i % 3) * 2.0) * delta
		spark.position.y += sin(_bg_time * 0.5 + i) * 0.1
		
		# Pulsing transparency
		spark.modulate.a = 0.2 + (sin(_bg_time * 2.0 + i * 1.5) + 1.0) * 0.4
		
		# Wrap around screen
		if spark.position.x > 650.0:
			spark.position.x = -10.0
			spark.position.y = randf() * 360.0
