class_name TurnState
extends RefCounted

const MAX_PLAYED_TILES := 9

var turn_number: int
var hand: Hand
var wall: MahjongWall
var discard_pile: Array[Tile]


func _init(p_turn_number: int = 1, p_hand: Hand = null, p_wall: MahjongWall = null, p_discard_pile: Array[Tile] = []) -> void:
	turn_number = p_turn_number
	hand = p_hand
	wall = p_wall
	discard_pile = p_discard_pile


func start() -> int:
	if hand == null or wall == null:
		return 0
	return hand.draw_to_full(wall)


func preview(selected_tiles: Array) -> Dictionary:
	return PatternMatcher.match_pattern(selected_tiles)


func play(selected_tiles: Array, added_score: int = 0, multiplier_mod: float = 1.0) -> Dictionary:
	if selected_tiles.is_empty() or selected_tiles.size() > MAX_PLAYED_TILES:
		return _empty_result(true)

	var pattern := preview(selected_tiles)
	if pattern.is_empty():
		return _empty_result(true)

	if hand != null and not hand.remove_tiles(selected_tiles):
		return _empty_result(false)

	for tile in selected_tiles:
		discard_pile.append(tile)

	var score_data := Scorer.score(pattern, added_score, multiplier_mod)
	score_data["skipped"] = false
	score_data["valid"] = true
	score_data["played_tiles"] = selected_tiles.duplicate()
	return score_data


func skip() -> Dictionary:
	return _empty_result(true)


func _empty_result(is_valid_action: bool) -> Dictionary:
	return {
		"pattern": "",
		"pattern_id": "",
		"base_score": 0,
		"added_score": 0,
		"pattern_mult": 0.0,
		"multiplier_mod": 1.0,
		"final_score": 0,
		"skipped": true,
		"valid": is_valid_action,
		"played_tiles": [],
	}
