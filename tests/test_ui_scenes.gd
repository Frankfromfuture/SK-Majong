extends GutTest

const MainScene = preload("res://src/scenes/main_menu/main.tscn")
const BattleScene = preload("res://src/scenes/battle/battle.tscn")
const RulesScene = preload("res://src/scenes/rules/rules.tscn")
const MahjongTile3DScript = preload("res://src/ui/mahjong_tile_3d.gd")


func test_main_menu_exposes_english_start_and_quit_buttons() -> void:
	var scene := MainScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	assert_not_null(_find_button(scene, "Start Run"))
	assert_not_null(_find_button(scene, "Quit"))
	assert_not_null(_find_label(scene, "Sangoku\nMahjong"))
	assert_not_null(scene.find_child("StartRunButton", true, false))
	assert_not_null(scene.find_child("MainTitle", true, false))
	assert_not_null(scene.find_child("LogoSprite", true, false))
	assert_not_null(scene.find_child("LanternRightSprite", true, false))
	assert_not_null(scene.find_child("HighestScoreValue", true, false))
	assert_not_null(scene.find_child("BonusMultiplierValue", true, false))
	assert_not_null(scene.find_child("MenuTile_Wan_01", true, false))
	assert_lt((scene.find_child("LeftBannerSprite", true, false) as Control).size.x, 60.0)
	assert_lt((scene.find_child("LogoSprite", true, false) as Control).size.x, 110.0)
	assert_eq(scene.find_child("DecorationLayer", true, false).mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(scene.find_child("FxLayer", true, false).mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_battle_scene_starts_with_thirteen_hand_tiles() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	var hand_tiles := _find_nodes_by_prefix(scene, "HandTile_")
	var draw_tiles := _find_nodes_by_prefix(scene, "DrawTile_")
	assert_eq(hand_tiles.size(), 13, "Battle should start with a 13-tile hand")
	assert_eq(draw_tiles.size(), 0, "There should be no draw tiles before the first play")
	assert_not_null(scene.find_child("HandTile3DShowcase", true, false))
	var hand_showcase := scene.find_child("HandTile3DShowcase", true, false) as Control
	var draw_showcase := scene.find_child("DrawTile3DShowcase", true, false) as Control
	var wall_panel := scene.find_child("TileWallPanel", true, false) as Control
	var hand_viewport: SubViewport = hand_showcase.find_child("Tile3DViewport", true, false) as SubViewport
	assert_not_null(hand_viewport)
	assert_gte(hand_viewport.size.x, 1024)
	if draw_showcase != null:
		assert_lt(hand_showcase.position.x, draw_showcase.position.x)
		assert_lt(draw_showcase.position.x + draw_showcase.size.x * draw_showcase.scale.x, wall_panel.position.x)
	assert_eq((hand_tiles[0] as Button).text, "", "2D tile button text should be hidden behind 3D tiles")
	assert_eq((hand_tiles[0] as Button).tooltip_text, "", "2D tile hover tooltip should be hidden behind 3D hover")
	assert_eq((hand_tiles[0] as Button).mouse_filter, Control.MOUSE_FILTER_IGNORE, "2D tile button should not receive hover")
	assert_eq(hand_showcase.mouse_filter, Control.MOUSE_FILTER_STOP, "3D hand layer should own hover")

	# Duel UI nodes
	assert_not_null(scene.find_child("RoundValue", true, false))
	assert_not_null(scene.find_child("PlayerHpValue", true, false))
	assert_not_null(scene.find_child("DefenseValue", true, false))
	assert_not_null(scene.find_child("MoneyValue", true, false))
	assert_not_null(scene.find_child("EnemyHpValue", true, false))
	assert_not_null(scene.find_child("EnemyAttackCountdownValue", true, false))
	assert_not_null(scene.find_child("OpenMeldLedgerPanel", true, false))
	assert_not_null(scene.find_child("TileWallPanel", true, false))
	assert_not_null(scene.find_child("AllyUnit_00", true, false))
	assert_not_null(scene.find_child("EnemyWarlordUnit", true, false))
	assert_not_null(scene.find_child("EnemyIntentBox", true, false))
	assert_not_null(scene.find_child("PatternBurstLabel", true, false))
	assert_not_null(scene.find_child("StatusValue", true, false))
	assert_not_null(scene.find_child("PlayTilesButton", true, false))
	assert_not_null(scene.find_child("UltimateWinButton", true, false))
	assert_not_null(scene.find_child("HitsButton", true, false))
	assert_not_null(scene.find_child("MainMenuButton", true, false))
	assert_not_null(scene.find_child("PatternToggleButton", true, false))
	assert_null(scene.find_child("SortByRankButton", true, false))
	assert_null(scene.find_child("NewRunButton", true, false))
	assert_null(scene.find_child("FinishBattleButton", true, false))
	assert_null(scene.find_child("PatternListPanel", true, false), "Rules list should live in the rules scene, not battle")


func test_battle_scene_has_future_slot_placeholders() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	# 4.0 Warlord slots
	assert_not_null(scene.find_child("WarlordSlot_00", true, false))
	assert_not_null(scene.find_child("WarlordSlot_01", true, false))
	assert_not_null(scene.find_child("WarlordSlot_02", true, false))

	# 3.0 Flower/Season buff bar
	assert_not_null(scene.find_child("FlowerSeasonBuffBar", true, false))
	assert_not_null(scene.find_child("BuffSlot_00", true, false))

	# 5.0 Consumable bar
	assert_not_null(scene.find_child("ConsumableBar", true, false))
	assert_not_null(scene.find_child("ConsumableSlot_00", true, false))

	assert_null(scene.find_child("PatternRow_00", true, false))


func test_rules_scene_owns_pattern_list() -> void:
	var scene := RulesScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	assert_not_null(scene.find_child("RulesBackButton", true, false))
	assert_not_null(scene.find_child("PatternListPanel", true, false))
	assert_not_null(scene.find_child("PatternRow_00", true, false))
	assert_not_null(scene.find_child("PatternRow_11", true, false))


func test_battle_scene_has_3d_tile_texture_assets() -> void:
	assert_true(FileAccess.file_exists("res://assets/sprites/battle/Textures/TileFace_Wan_01.png"))
	assert_true(FileAccess.file_exists("res://assets/sprites/battle/Textures/TileFace_Tong_09.png"))
	assert_true(FileAccess.file_exists("res://assets/sprites/battle/Textures/TileFace_Suo_09.png"))
	assert_true(FileAccess.file_exists("res://assets/sprites/battle/Textures/TileFace_Wind_East.png"))
	assert_true(FileAccess.file_exists("res://assets/sprites/battle/Textures/TileFace_Dragon_White.png"))
	var image := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/battle/Textures/TileFace_Wan_01.png"))
	assert_eq(image.get_size(), Vector2i(1024, 1536))


func test_3d_tile_uses_texture_face_when_asset_exists() -> void:
	var tile_3d: Node3D = MahjongTile3DScript.new()
	add_child_autofree(tile_3d)
	tile_3d.call("setup", Tile.man(1), false, 0.0)
	assert_not_null(tile_3d.find_child("TileFaceSprite", true, false))
	assert_null(tile_3d.find_child("TileFaceLabel", true, false))
	tile_3d.call("set_hovered", true)
	assert_not_null(tile_3d.find_child("TileHoverGlow", true, false))


func test_battle_scene_state_initializes_correctly() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	assert_not_null(scene.state, "DuelBattleState should be initialized")
	assert_eq(scene.state.hand.size(), 13, "Battle should start with a 13-tile hand")
	assert_eq(scene.state.drawn.size(), 0, "No tiles should be drawn before the first play")
	assert_eq(scene.state.discard_pile.size(), 3, "Opening should discard 3 tiles")
	assert_eq(scene.state.turn_number, 1, "Should start at turn 1")
	assert_false(scene.state.is_complete, "Should not be complete at start")


func test_played_tile_count_controls_next_draw_and_auto_merge() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	scene.state.hand.clear()
	scene.state.hand.add_tiles([
		Tile.man(1), Tile.man(2), Tile.man(3),
		Tile.pin(1), Tile.pin(2), Tile.pin(3),
		Tile.sou(1), Tile.sou(2), Tile.sou(3),
		Tile.man(5), Tile.man(5), Tile.pin(9), Tile.sou(9),
	])
	scene.state.drawn.clear()
	scene._build_ui()

	scene.selected = {
		"0:0": {"zone": DuelBattleState.TileZone.HAND, "index": 0},
	}
	scene._on_play_tiles_pressed()
	await wait_process_frames(90)

	assert_eq(scene.state.hand.size(), 13)
	assert_eq(scene.state.drawn.size(), 0)
	assert_eq(scene.state.turn_number, 2)

	scene.selected = {
		"0:0": {"zone": DuelBattleState.TileZone.HAND, "index": 0},
		"0:1": {"zone": DuelBattleState.TileZone.HAND, "index": 1},
		"0:2": {"zone": DuelBattleState.TileZone.HAND, "index": 2},
	}
	scene._on_play_tiles_pressed()
	await wait_process_frames(90)

	assert_eq(scene.state.hand.size(), 13)
	assert_eq(scene.state.drawn.size(), 0)
	assert_eq(scene.state.turn_number, 3)


func test_hits_button_shows_archived_and_scattered_totals() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	scene.state.played_sets.clear()
	scene.state.played_sets.append_array([
		{
			"id": "sequence",
			"tiles": ["1 Sou", "2 Sou", "3 Sou"],
			"effects": [{"type": "damage", "value": 30}],
		},
		{
			"id": "scattered",
			"tiles": ["1 Sou", "5 Man", "9 Pin"],
			"effects": [],
		},
	])
	scene._on_hits_pressed()
	await wait_process_frames(1)

	assert_not_null(scene.find_child("HitsStatsPanel", true, false))
	var attack_total := scene.find_child("HitsAttackTotal", true, false) as Label
	assert_not_null(attack_total)
	assert_string_contains(attack_total.text, "30")
	assert_not_null(scene.find_child("HitsRow_00", true, false))
	assert_not_null(scene.find_child("HitsRow_01", true, false))


func test_duel_battle_display_shows_round_one() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	var round_label: Label = scene.find_child("RoundValue", true, false) as Label
	assert_not_null(round_label)
	assert_string_contains(round_label.text, "1")


func _find_button(root: Node, button_text: String) -> Button:
	if root is Button and root.text == button_text:
		return root
	for child in root.get_children():
		var found := _find_button(child, button_text)
		if found != null:
			return found
	return null


func _find_label(root: Node, label_text: String) -> Label:
	if root is Label and root.text == label_text:
		return root
	for child in root.get_children():
		var found := _find_label(child, label_text)
		if found != null:
			return found
	return null


func _find_nodes_by_prefix(root: Node, prefix: String) -> Array:
	var result := []
	if root.name.begins_with(prefix):
		result.append(root)
	for child in root.get_children():
		result.append_array(_find_nodes_by_prefix(child, prefix))
	return result
