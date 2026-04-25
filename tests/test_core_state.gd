extends GutTest

const TileScript = preload("res://src/core/tile.gd")
const HandScript = preload("res://src/core/hand.gd")
const WallScript = preload("res://src/core/wall.gd")
const BattleStateScript = preload("res://src/core/battle_state.gd")


func test_wall_builds_standard_108_tile_set() -> void:
	var wall := WallScript.new(false)
	wall.reset(false)
	assert_eq(wall.remaining_count(), 108)


func test_wall_draw_reduces_remaining_count() -> void:
	var wall := WallScript.new(false)
	wall.reset(false)
	var drawn := wall.draw(13)
	assert_eq(drawn.size(), 13)
	assert_eq(wall.remaining_count(), 95)


func test_hand_draw_to_full_caps_at_thirteen() -> void:
	var wall := WallScript.new(false)
	wall.reset(false)
	var hand := HandScript.new()
	var drawn := hand.draw_to_full(wall)
	assert_eq(drawn, 13)
	assert_eq(hand.size(), 13)
	assert_eq(wall.remaining_count(), 95)


func test_hand_remove_tiles_uses_tile_identity_by_value() -> void:
	var hand := HandScript.new()
	hand.add_tiles([m(1), m(1), m(2), p(5)])
	assert_true(hand.remove_tiles([m(1), m(2)]))
	assert_eq(hand.size(), 2)
	assert_eq(hand.to_display_string(), "1万 5筒")


func test_battle_scores_turn_and_refills_hand() -> void:
	var battle := BattleStateScript.new(100, 1234)
	battle.hand.clear()
	battle.hand.add_tiles([m(1), m(2), m(3), p(1), p(2), p(3), s(1), s(2), s(3), m(5), m(5), p(9), s(9)])

	var result := battle.play_turn([m(1), m(2), m(3)])

	assert_true(result.get("valid", false))
	assert_eq(result.get("pattern_id", ""), "sequence")
	assert_eq(result.get("final_score", -1), 60)
	assert_eq(battle.total_score, 60)
	assert_eq(battle.current_turn, 2)
	assert_eq(battle.hand.size(), 13)


func test_battle_skip_counts_as_turn_without_score() -> void:
	var battle := BattleStateScript.new(100, 5678)
	var result := battle.skip_turn()
	assert_true(result.get("valid", false))
	assert_true(result.get("skipped", false))
	assert_eq(battle.total_score, 0)
	assert_eq(battle.current_turn, 2)
	assert_eq(battle.skipped_turn_count(), 1)


func m(rank: int) -> Tile:
	return TileScript.man(rank)


func p(rank: int) -> Tile:
	return TileScript.pin(rank)


func s(rank: int) -> Tile:
	return TileScript.sou(rank)
