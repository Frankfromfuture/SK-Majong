class_name BattleState
extends RefCounted

const MAX_TURNS := 4

var target_score: int
var total_score := 0
var current_turn := 1
var wall: MahjongWall
var hand: Hand
var discard_pile: Array[Tile] = []
var turn_results: Array[Dictionary] = []


func _init(p_target_score: int = 100, seed: int = 0) -> void:
	setup(p_target_score, seed)


func setup(p_target_score: int, seed: int = 0) -> void:
	target_score = p_target_score
	total_score = 0
	current_turn = 1
	discard_pile.clear()
	turn_results.clear()
	wall = MahjongWall.new(false)
	wall.reset(true, seed)
	hand = Hand.new()
	hand.draw_to_full(wall)


func can_play_turn() -> bool:
	return current_turn <= MAX_TURNS


func make_turn_state() -> TurnState:
	return TurnState.new(current_turn, hand, wall, discard_pile)


func play_turn(selected_tiles: Array, added_score: int = 0, multiplier_mod: float = 1.0) -> Dictionary:
	if not can_play_turn():
		return {"valid": false, "reason": "battle_finished"}

	var turn_state := make_turn_state()
	var result := turn_state.play(selected_tiles, added_score, multiplier_mod)
	_apply_turn_result(result)
	return result


func skip_turn() -> Dictionary:
	if not can_play_turn():
		return {"valid": false, "reason": "battle_finished"}

	var turn_state := make_turn_state()
	var result := turn_state.skip()
	_apply_turn_result(result)
	return result


func is_finished() -> bool:
	return current_turn > MAX_TURNS or total_score >= target_score


func is_won() -> bool:
	return total_score >= target_score


func skipped_turn_count() -> int:
	var count := 0
	for result in turn_results:
		if result.get("skipped", false):
			count += 1
	return count


func _apply_turn_result(result: Dictionary) -> void:
	if not result.get("valid", false):
		return

	total_score += int(result.get("final_score", 0))
	turn_results.append(result)
	current_turn += 1
	if can_play_turn():
		hand.draw_to_full(wall)
