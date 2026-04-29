extends SceneTree


func _init() -> void:
	var state := DuelBattleState.new()
	state.start_run(7)
	_assert(state.remaining_deck() + state.hand.size() + state.drawn.size() == MahjongWall.TOTAL_TILE_COUNT, "wall_total")
	_assert(state.hand.size() == DuelBattleState.INITIAL_HAND_SIZE, "initial_hand_13")
	_assert(state.drawn.size() == 1, "first_action_draw_1")

	state.accept_drawn_into_hand()
	_assert(state.hand.size() == DuelBattleState.HAND_LIMIT, "merged_to_14")

	state.hand.add_tile(Tile.man(9))
	_assert(state.is_discard_required(), "discard_required_over_14")
	var discard_result := state.discard_selected([{"zone": DuelBattleState.TileZone.HAND, "index": state.hand.size() - 1}])
	_assert(bool(discard_result.get("valid", false)), "discard_valid")
	_assert(not state.is_discard_required(), "discard_resolved")

	state = DuelBattleState.new()
	state.start_run(11)
	state.accept_drawn_into_hand()
	state.hand.clear()
	state.hand.add_tiles([Tile.sou(1), Tile.sou(2), Tile.sou(3)])
	state.enemy_army_defense = 80
	state.enemy_city_defense = 160
	state.drawn.clear()
	var play_result := state.play_tiles([
		{"zone": DuelBattleState.TileZone.HAND, "index": 0},
		{"zone": DuelBattleState.TileZone.HAND, "index": 1},
		{"zone": DuelBattleState.TileZone.HAND, "index": 2},
	])
	_assert(bool(play_result.get("valid", false)), "sequence_play_valid")
	_assert(state.enemy_army_defense == 14, "sou_sequence_breaks_army")
	_assert(state.enemy_city_defense == 160, "army_absorbs_sequence")
	_assert(state.open_melds.size() == 1, "sequence_enters_battlefield")

	state = DuelBattleState.new()
	state.start_run(13)
	state.accept_drawn_into_hand()
	state.hand.clear()
	state.hand.add_tiles([
		Tile.sou(1), Tile.sou(2), Tile.sou(3),
		Tile.pin(1), Tile.pin(2), Tile.pin(3),
		Tile.man(4), Tile.man(5), Tile.man(6),
		Tile.man(7), Tile.man(8), Tile.man(9),
		Tile.man(2), Tile.man(2),
	])
	state.enemy_army_defense = 0
	state.enemy_city_defense = 1000
	state.drawn.clear()
	var hu_check := state.play_tiles([])
	_assert(bool(hu_check.get("pending_hu", false)), "pass_can_trigger_hu_choice")
	var assault := state.ultimate_win()
	_assert(bool(assault.get("valid", false)), "assault_valid")
	_assert(int(assault.get("damage", 0)) == 504, "assault_damage")
	_assert(int(assault.get("defense", 0)) == 664, "assault_defense")
	_assert(state.enemy_city_defense == 496, "assault_does_not_end_by_itself")
	_assert(state.hand.size() == DuelBattleState.INITIAL_HAND_SIZE, "assault_resets_hand")
	_assert(state.drawn.size() == 1, "assault_prepares_next_draw")

	print("rule_smoke_test: ok")
	quit(0)


func _assert(condition: bool, label: String) -> void:
	if condition:
		return
	push_error("rule_smoke_test failed: %s" % label)
	quit(1)
