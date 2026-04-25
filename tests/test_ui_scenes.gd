extends GutTest

const MainScene = preload("res://src/scenes/main_menu/main.tscn")
const BattleScene = preload("res://src/scenes/battle/battle.tscn")
const TileCardScript = preload("res://src/ui/tile_card.gd")


func test_main_menu_exposes_english_start_and_quit_buttons() -> void:
	var scene := MainScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	assert_not_null(_find_button(scene, "Start Run"))
	assert_not_null(_find_button(scene, "Quit"))
	assert_not_null(_find_label(scene, "Sangoku\nMahjong"))


func test_battle_scene_starts_with_thirteen_tile_cards() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	var cards := _find_tile_cards(scene)
	assert_eq(cards.size(), 13)
	assert_not_null(_find_label(scene, "Score Preview"))
	assert_not_null(_find_button(scene, "Play Set"))


func test_battle_scene_can_select_sequence_and_score() -> void:
	var scene := BattleScene.instantiate()
	add_child_autofree(scene)
	await wait_process_frames(2)

	scene.battle.hand.clear()
	scene.battle.hand.add_tiles([
		Tile.man(1), Tile.man(2), Tile.man(3),
		Tile.pin(1), Tile.pin(2), Tile.pin(3),
		Tile.sou(1), Tile.sou(2), Tile.sou(3),
		Tile.man(5), Tile.man(5), Tile.pin(9), Tile.sou(9),
	])
	scene._refresh_hand()
	await wait_process_frames(1)

	var cards := _find_tile_cards(scene)
	for card in cards:
		if card.tile.suit == Tile.Suit.MAN and card.tile.rank in [1, 2, 3]:
			scene._on_tile_pressed(card)
	await wait_process_frames(1)

	assert_eq(scene.preview_pattern_label.text, "Pattern  SEQUENCE")
	assert_eq(scene.preview_score_label.text, "Score  60")
	assert_false(scene.play_button.disabled)

	scene._on_play_pressed()
	await wait_process_frames(4)
	assert_eq(scene.battle.total_score, 60)
	assert_eq(scene.battle.current_turn, 2)
	assert_eq(_find_tile_cards(scene).size(), 13)


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


func _find_tile_cards(root: Node) -> Array:
	var cards := []
	if is_instance_of(root, TileCardScript):
		cards.append(root)
	for child in root.get_children():
		cards.append_array(_find_tile_cards(child))
	return cards
