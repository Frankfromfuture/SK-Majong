extends GutTest

const DuelBattleStateScript = preload("res://src/core/duel_battle_state.gd")
const HandScript = preload("res://src/core/hand.gd")
const TileScript = preload("res://src/core/tile.gd")


func test_duel_auto_keeps_13_from_opening_16_and_draws_3() -> void:
	var state := _make_state()

	assert_eq(state.hand.size(), 13)
	assert_eq(state.drawn.size(), 3)
	assert_eq(state.discard_pile.size(), 3)
	assert_eq(state.player_hp, 100)
	assert_eq(state.enemy_hp, 160)
	assert_eq(state.enemy_attack_countdown, 3)


func test_play_sequence_records_open_meld_and_sou_deals_damage() -> void:
	var state := _make_state()
	_set_hand(state, [s(1), s(2), s(3), m(1), m(2), m(3), p(1), p(2), p(3), m(5), m(5), p(9), e()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_eq(state.open_melds.size(), 1)
	assert_eq(state.open_melds[0].get("id", ""), "sequence")
	assert_eq(state.open_melds[0].get("effect_type", ""), "damage")
	assert_eq(state.enemy_hp, 130)
	assert_eq(state.hand.size(), 13)
	assert_eq(state.drawn.size(), 3)


func test_man_triplet_adds_money() -> void:
	var state := _make_state()
	_set_hand(state, [m(1), m(1), m(1), s(1), s(2), s(3), p(1), p(2), p(3), m(5), m(5), p(9), e()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_eq(state.money, 30)
	assert_eq(state.enemy_hp, 160)


func test_pin_triplet_adds_defense() -> void:
	var state := _make_state()
	_set_hand(state, [p(2), p(2), p(2), s(1), s(2), s(3), m(1), m(2), m(3), m(5), m(5), p(9), e()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_eq(state.open_melds[0].get("id", ""), "triplet")
	assert_eq(state.player_defense, 30)


func test_dragon_and_wind_resources_are_mapped() -> void:
	var state := _make_state()
	_set_hand(state, [TileScript.red(), TileScript.red(), TileScript.red(), TileScript.green(), TileScript.green(), TileScript.green(), TileScript.white(), TileScript.white(), TileScript.white(), e(), e(), e(), m(9)])

	assert_true(state.play_tiles(_first_matching(state, Tile.Suit.DRAGON, 1, 3)).get("valid", false))
	assert_eq(state.enemy_hp, 130)
	assert_true(state.play_tiles(_first_matching(state, Tile.Suit.DRAGON, 2, 3)).get("valid", false))
	assert_eq(state.money, 30)
	assert_true(state.play_tiles(_first_matching(state, Tile.Suit.DRAGON, 3, 3)).get("valid", false))
	assert_eq(state.player_defense, 6) # 30 defense then enemy attack for 24 on the third turn.
	assert_true(state.play_tiles(_first_matching(state, Tile.Suit.WIND, 1, 3)).get("valid", false))
	assert_gt(state.tempo, 0)


func test_pair_plus_single_triggers_weak_pair_and_base_single() -> void:
	var state := _make_state()
	_set_hand(state, [m(4), m(4), s(9), p(1), p(2), p(3), s(1), s(2), s(3), m(5), m(5), p(9), e()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_eq(result.get("play", {}).get("id", ""), "pair_single")
	assert_eq(state.money, 20)
	assert_eq(state.enemy_hp, 150)
	assert_eq(state.open_melds.size(), 0)


func test_scattered_records_without_scoring_effects() -> void:
	var state := _make_state()
	_set_hand(state, [s(1), m(5), p(9), p(1), p(2), p(3), s(3), s(4), s(5), m(7), m(7), e(), TileScript.white()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_eq(result.get("play", {}).get("id", ""), "scattered")
	assert_eq(state.enemy_hp, 160)
	assert_eq(state.money, 0)
	assert_eq(state.player_defense, 0)
	assert_eq(state.scatter_ledger.size(), 1)


func test_play_three_refills_hand_to_13_and_advances_turn() -> void:
	var state := _make_state()

	var result := state.play_tiles(_draw_three())

	assert_true(result.get("valid", false))
	assert_eq(state.hand.size(), 13)
	assert_eq(state.drawn.size(), 3)
	assert_eq(state.turn_number, 2)
	assert_eq(state.player_turns_taken, 1)


func test_enemy_attacks_every_three_player_turns() -> void:
	var state := _make_state()
	state.player_defense = 10

	for _i in range(3):
		state.drawn = [m(1), m(5), m(9)]
		var result := state.play_tiles(_draw_three())
		assert_true(result.get("valid", false))

	assert_eq(state.player_turns_taken, 3)
	assert_eq(state.enemy_attack_countdown, 3)
	assert_eq(state.player_defense, 0)
	assert_eq(state.player_hp, 86)


func test_ultimate_win_uses_open_and_concealed_melds_with_multiplier() -> void:
	var state := _make_state()
	_set_hand(state, [s(1), s(2), s(3), p(1), p(2), p(3), TileScript.red(), TileScript.red(), TileScript.red(), m(5), m(5), p(8), m(9)])
	state.drawn.clear()
	state.open_melds = [
		{"id": "sequence", "suit": Tile.Suit.SOU, "effect_value": 30},
	]

	var result := state.ultimate_win()

	assert_true(result.get("valid", false))
	assert_eq(result.get("multiplier", 0.0), 3.75)
	assert_gt(result.get("damage", 0), 0)
	assert_true(state.enemy_hp < 160)


func test_enemy_hp_zero_wins() -> void:
	var state := _make_state()
	state.enemy_hp = 20
	_set_hand(state, [s(1), s(2), s(3), m(1), m(2), m(3), p(1), p(2), p(3), m(5), m(5), p(9), e()])

	var result := state.play_tiles([_hand(0), _hand(1), _hand(2)])

	assert_true(result.get("valid", false))
	assert_true(state.is_complete)
	assert_eq(state.result, DuelBattleState.BattleResult.WIN)


func _make_state() -> DuelBattleState:
	var state := DuelBattleStateScript.new()
	state.start_run(1234)
	return state


func _set_hand(state: DuelBattleState, tiles: Array) -> void:
	state.hand = HandScript.new(DuelBattleState.INITIAL_HAND_SIZE)
	state.hand.add_tiles(tiles)


func _hand(index: int) -> Dictionary:
	return {"zone": DuelBattleState.TileZone.HAND, "index": index}


func _draw(index: int) -> Dictionary:
	return {"zone": DuelBattleState.TileZone.DRAW, "index": index}


func _draw_three() -> Array:
	return [_draw(0), _draw(1), _draw(2)]


func _first_matching(state: DuelBattleState, suit: int, rank: int, count: int) -> Array:
	var selections := []
	for i in range(state.hand.tiles.size()):
		var tile: Tile = state.hand.tiles[i]
		if tile.suit == suit and tile.rank == rank:
			selections.append(_hand(i))
			if selections.size() == count:
				return selections
	return selections


func m(rank: int) -> Tile:
	return TileScript.man(rank)


func p(rank: int) -> Tile:
	return TileScript.pin(rank)


func s(rank: int) -> Tile:
	return TileScript.sou(rank)


func e() -> Tile:
	return TileScript.east()
