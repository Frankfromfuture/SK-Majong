class_name DuelBattleState
extends RefCounted

const INITIAL_HAND_SIZE := 13
const HAND_LIMIT := 14
const MAX_HAND_STORAGE := 18
const MIN_PLAY_PER_TURN := 0
const MAX_PLAY_PER_TURN := 3
const KAN_PLAY_SIZE := 4
const MAX_ACTION_DRAW := 4
const ENEMY_ATTACK_INTERVAL := 3
const DEFAULT_PLAYER_GENERAL_HP := 100
const DEFAULT_ENEMY_ARMY_DEFENSE := 80
const DEFAULT_ENEMY_CITY_DEFENSE := 160
const DEFAULT_ENEMY_ATTACK := 24
const ARMY_BREAK_BONUS := 1.1
const CITY_BREAK_BONUS := 1.1
const BASE_WIN_MULTIPLIER := 2.0
const SINGLE_MULTIPLIER := 1.0
const SCATTERED_MULTIPLIER := 1.0
const PAIR_MULTIPLIER := 2.5
const SEQUENCE_MULTIPLIER := 4.0
const TRIPLET_MULTIPLIER := 5.0
const KAN_MULTIPLIER := 8.0
const WIN_PAIR_MULTIPLIER := 5.0
const BATTLEFIELD_WIN_WEIGHT := 1.0
const HAND_WIN_WEIGHT := 2.0

enum TileZone {
	HAND,
	DRAW,
	OPENING,
}

enum BattleResult {
	ONGOING,
	WIN,
	LOSE,
}

var hand: Hand
var opening_choices: Array[Tile] = []
var drawn: Array[Tile] = []
var wall: MahjongWall
var discard_pile: Array[Tile] = []
var open_melds: Array[Dictionary] = []
var played_sets: Array[Dictionary] = []
var turn_number := 1
var player_turns_taken := 0
var enemy_attack_countdown := ENEMY_ATTACK_INTERVAL
var player_general_hp := DEFAULT_PLAYER_GENERAL_HP
var player_army_defense := 0
var enemy_army_defense := DEFAULT_ENEMY_ARMY_DEFENSE
var enemy_city_defense := DEFAULT_ENEMY_CITY_DEFENSE
var enemy_attack := DEFAULT_ENEMY_ATTACK
var is_complete := false
var result := BattleResult.ONGOING
var pending_hu_choice := false
var last_regular_play_count := 0
var last_action_was_kan := false
var last_event := ""
var last_play_preview := {}
var last_draw_count := 0


func start_run(seed: int = 0, _auto_choose_opening: bool = true) -> void:
	wall = MahjongWall.new(false)
	wall.reset(true, seed, true)
	hand = Hand.new(MAX_HAND_STORAGE)
	opening_choices.clear()
	drawn.clear()
	discard_pile.clear()
	open_melds.clear()
	played_sets.clear()
	turn_number = 1
	player_turns_taken = 0
	enemy_attack_countdown = ENEMY_ATTACK_INTERVAL
	player_general_hp = DEFAULT_PLAYER_GENERAL_HP
	player_army_defense = 0
	enemy_army_defense = DEFAULT_ENEMY_ARMY_DEFENSE
	enemy_city_defense = DEFAULT_ENEMY_CITY_DEFENSE
	enemy_attack = DEFAULT_ENEMY_ATTACK
	is_complete = false
	result = BattleResult.ONGOING
	pending_hu_choice = false
	last_regular_play_count = 0
	last_action_was_kan = false
	last_event = "Opening hand: 13 tiles"
	last_play_preview.clear()
	last_draw_count = 0
	hand.add_tiles(wall.draw(INITIAL_HAND_SIZE))
	hand.sort_in_place()
	_draw_for_action_start()


func choose_initial_hand(_indices: Array[int]) -> Dictionary:
	return _invalid("opening_removed")


func accept_drawn_into_hand() -> void:
	for tile in drawn:
		hand.add_tile(tile)
	drawn.clear()
	hand.sort_in_place()
	if is_discard_required():
		last_event = "Discard %d tile(s) before acting" % required_discard_count()


func can_select(zone: int, index: int) -> bool:
	if zone == TileZone.DRAW:
		return index >= 0 and index < drawn.size()
	if zone == TileZone.OPENING:
		return index >= 0 and index < opening_choices.size()
	return index >= 0 and index < hand.size()


func is_discard_required() -> bool:
	return hand != null and hand.size() > HAND_LIMIT


func required_discard_count() -> int:
	return max(0, hand.size() - HAND_LIMIT) if hand != null else 0


func preview_play(selections: Array) -> Dictionary:
	if pending_hu_choice:
		return _invalid("resolve_hu_choice")
	if is_discard_required():
		return _invalid("discard_required")
	if not _selections_are_unique_and_valid(selections):
		return _invalid("invalid_selection")
	var tiles := _tiles_from_selections(selections)
	var play := classify_play(tiles)
	if play.get("id", "") == "invalid":
		return _invalid(str(play.get("reason", "invalid_selection")))
	var preview := play.duplicate(true)
	preview["effects"] = _preview_effects(play, tiles)
	return {"valid": true, "play": preview}


func play_tiles(selections: Array) -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	if pending_hu_choice:
		return _invalid("resolve_hu_choice")
	if is_discard_required():
		return _invalid("discard_required")
	if not _selections_are_unique_and_valid(selections):
		return _invalid("invalid_selection")

	var tiles := _tiles_from_selections(selections)
	var play := classify_play(tiles)
	if play.get("id", "") == "invalid":
		return _invalid(str(play.get("reason", "invalid_selection")))

	var effects := _apply_play_effects(play, tiles)
	play["effects"] = effects
	play["effect_type"] = _primary_effect_type(effects)
	play["effect_value"] = _primary_effect_value(effects)
	play["tiles"] = _tile_names(tiles)
	play["tile_objects"] = _duplicate_tiles(tiles)
	last_play_preview = play.duplicate(true)

	if play.get("id", "") != "pass":
		played_sets.append(play.duplicate(true))
	if _enters_battlefield(play):
		open_melds.append(play.duplicate(true))

	_remove_selected_tiles(selections, false)
	drawn.clear()
	hand.sort_in_place()
	last_regular_play_count = _regular_play_count_for(play, tiles)
	last_action_was_kan = str(play.get("id", "")) == "kan"

	_check_battle_result()
	if is_complete:
		last_event = "%s: %s" % [str(play.get("name", "Play")), _effects_to_text(effects)]
		return {"valid": true, "play": play.duplicate(true), "enemy_attack": {}, "pending_hu": false, "event": last_event}

	if not get_win_breakdown().is_empty():
		pending_hu_choice = true
		last_event = "%s. Total Assault ready." % _play_event_text(play, effects)
		return {"valid": true, "play": play.duplicate(true), "enemy_attack": {}, "pending_hu": true, "event": last_event}

	var enemy_attack_event := _finish_player_action()
	last_event = "%s Draw %d next." % [_play_event_text(play, effects), last_draw_count]
	return {
		"valid": true,
		"play": play.duplicate(true),
		"enemy_attack": enemy_attack_event,
		"pending_hu": false,
		"draw_count": last_draw_count,
		"event": last_event,
	}


func play_meld(selections: Array) -> Dictionary:
	return play_tiles(selections)


func discard_selected(selections: Array) -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	if pending_hu_choice:
		return _invalid("resolve_hu_choice")
	if not is_discard_required():
		return _invalid("discard_not_required")
	if selections.is_empty() or selections.size() > required_discard_count():
		return _invalid("discard_count")
	if not _selections_are_unique_and_valid(selections):
		return _invalid("invalid_selection")
	for selection in selections:
		if int(selection.get("zone", -1)) != TileZone.HAND:
			return _invalid("discard_from_hand")
	_remove_selected_tiles(selections, true)
	hand.sort_in_place()
	selected_after_discard_cleanup()
	last_event = "Discarded %d. %s" % [selections.size(), action_prompt()]
	return {"valid": true, "event": last_event, "discard_required": is_discard_required()}


func selected_after_discard_cleanup() -> void:
	if not is_discard_required():
		last_event = "Ready to act"


func decline_ultimate_win() -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	if not pending_hu_choice:
		return _invalid("not_pending_hu")
	pending_hu_choice = false
	var enemy_attack_event := _finish_player_action()
	last_event = "Total Assault skipped. Draw %d next." % last_draw_count
	return {"valid": true, "enemy_attack": enemy_attack_event, "draw_count": last_draw_count, "event": last_event}


func can_ultimate_win() -> bool:
	return not is_discard_required() and not get_win_breakdown().is_empty()


func get_win_breakdown() -> Dictionary:
	if hand == null:
		return {}
	var open_count: int = min(open_melds.size(), 4)
	var required_concealed: int = max(0, 4 - open_count)
	var breakdown := _find_concealed_breakdown(hand.tiles, required_concealed)
	if breakdown.is_empty():
		return {}
	breakdown["battlefield_melds"] = open_melds.slice(0, open_count)
	return breakdown


func current_win_multiplier() -> float:
	return BASE_WIN_MULTIPLIER


func ultimate_win() -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	if not pending_hu_choice:
		return _invalid("not_pending_hu")
	var breakdown := get_win_breakdown()
	if breakdown.is_empty():
		return _invalid("not_ready")

	var components := _ordered_hu_components(_build_hu_components(breakdown))
	var effects: Array[Dictionary] = []
	var total_damage := 0
	var defense_gain := 0
	for component in components:
		var effect := _resolve_hu_component(component)
		if effect.is_empty():
			continue
		effects.append(effect)
		if str(effect.get("type", "")) == "army_defense":
			defense_gain += int(effect.get("value", 0))
		else:
			total_damage += int(effect.get("value", 0))

	pending_hu_choice = false
	_check_battle_result()
	var enemy_attack_event := {}
	if not is_complete:
		_reset_after_hu()
		enemy_attack_event = _finish_player_action()

	last_event = "TOTAL ASSAULT: %d damage, +%d army defense" % [total_damage, defense_gain]
	return {
		"valid": true,
		"damage": total_damage,
		"defense": defense_gain,
		"multiplier": current_win_multiplier(),
		"breakdown": breakdown,
		"effects": effects,
		"enemy_attack": enemy_attack_event,
		"event": last_event,
	}


func action_prompt() -> String:
	if is_complete:
		return "Battle complete"
	if pending_hu_choice:
		return "Choose Total Assault or Continue"
	if is_discard_required():
		return "Discard %d tile(s)" % required_discard_count()
	return "Play 0-3 tiles, or 4 matching tiles as Kan"


func remaining_deck() -> int:
	return wall.remaining_count() if wall != null else 0


static func classify_play(tiles: Array) -> Dictionary:
	if tiles.size() == 0:
		return {"id": "pass", "name": "Pass", "tile_count": 0, "open_meld": false}
	if tiles.size() == 1:
		return {"id": "single", "name": "Single", "tile_count": 1, "open_meld": false, "tile": tiles[0]}
	if tiles.size() == 2:
		if tiles[0].equals_tile(tiles[1]):
			return {"id": "pair", "name": "Pair", "tile_count": 2, "open_meld": false, "pair_tile": tiles[0]}
		return {"id": "scattered", "name": "Scattered", "tile_count": 2, "open_meld": false}
	if tiles.size() == 3 and PatternMatcher.is_triplet(tiles):
		return {"id": "triplet", "name": "Triplet", "tile_count": 3, "suit": tiles[0].suit, "open_meld": true}
	if tiles.size() == 3 and PatternMatcher.is_sequence(tiles):
		return {"id": "sequence", "name": "Sequence", "tile_count": 3, "suit": tiles[0].suit, "open_meld": true}
	if tiles.size() == 3:
		return {"id": "scattered", "name": "Scattered", "tile_count": 3, "open_meld": false}
	if tiles.size() == KAN_PLAY_SIZE:
		if PatternMatcher.is_kan(tiles):
			return {"id": "kan", "name": "Kan", "tile_count": 4, "suit": tiles[0].suit, "open_meld": true}
		return {"id": "invalid", "reason": "kan_requires_four_identical"}
	return {"id": "invalid", "reason": "play_zero_to_three_or_kan"}


static func classify_meld(tiles: Array) -> Dictionary:
	var play := classify_play(tiles)
	if play.get("id", "") == "sequence" or play.get("id", "") == "triplet" or play.get("id", "") == "kan":
		return play
	return {}


static func tile_point(tile: Tile) -> int:
	if tile == null:
		return 0
	match tile.suit:
		Tile.Suit.MAN:
			return tile.rank
		Tile.Suit.PIN, Tile.Suit.SOU:
			return 10 if tile.rank == 1 else tile.rank
	return 0


func _draw_for_action_start() -> void:
	var draw_count := _next_action_draw_count()
	drawn = wall.draw(draw_count)
	last_draw_count = drawn.size()


func _next_action_draw_count() -> int:
	var kan_bonus := 1 if last_action_was_kan else 0
	return min(last_regular_play_count + 1 + kan_bonus, MAX_ACTION_DRAW)


func _finish_player_action() -> Dictionary:
	player_turns_taken += 1
	enemy_attack_countdown -= 1
	var enemy_attack_event := {}
	if enemy_attack_countdown <= 0:
		enemy_attack_event = _enemy_attack()
		enemy_attack_countdown = ENEMY_ATTACK_INTERVAL

	_check_battle_result()
	if not is_complete:
		turn_number += 1
		_draw_for_action_start()
	return enemy_attack_event


func _preview_effects(play: Dictionary, tiles: Array) -> Array[Dictionary]:
	return _build_effects(play, tiles, false)


func _apply_play_effects(play: Dictionary, tiles: Array) -> Array[Dictionary]:
	return _build_effects(play, tiles, true)


func _build_effects(play: Dictionary, tiles: Array, apply: bool) -> Array[Dictionary]:
	var effect := _effect_for_play(play, tiles, apply)
	if effect.is_empty():
		return []
	return [effect]


func _effect_for_play(play: Dictionary, tiles: Array, apply: bool) -> Dictionary:
	var scoring_tiles := _scoring_tiles_for_play(play, tiles)
	if scoring_tiles.is_empty():
		return {}
	var suit: int = scoring_tiles[0].suit
	if suit != Tile.Suit.MAN and suit != Tile.Suit.PIN and suit != Tile.Suit.SOU:
		return {}
	var base_value := _score_tiles(scoring_tiles) * _play_multiplier(str(play.get("id", "")))
	return _resolve_suit_value(suit, base_value, apply)


func _resolve_hu_component(component: Dictionary) -> Dictionary:
	var tiles: Array = component.get("tiles", []) as Array
	if tiles.is_empty():
		return {}
	var suit: int = tiles[0].suit
	if suit != Tile.Suit.MAN and suit != Tile.Suit.PIN and suit != Tile.Suit.SOU:
		return {}
	var play_id := str(component.get("play_id", ""))
	var multiplier := WIN_PAIR_MULTIPLIER if play_id == "win_pair" else _play_multiplier(play_id)
	var weight := float(component.get("weight", 1.0))
	var base_value := _score_tiles(tiles) * multiplier * weight * BASE_WIN_MULTIPLIER
	var effect := _resolve_suit_value(suit, base_value, true)
	if not effect.is_empty():
		effect["source"] = str(component.get("source", ""))
		effect["play_id"] = play_id
		effect["tiles"] = _tile_names(tiles)
	return effect


func _resolve_suit_value(suit: int, base_value: float, apply: bool) -> Dictionary:
	var rounded_base := int(round(base_value))
	if rounded_base <= 0:
		return {}
	match suit:
		Tile.Suit.MAN:
			if apply:
				player_army_defense += rounded_base
			return {"type": "army_defense", "value": rounded_base, "base_value": rounded_base}
		Tile.Suit.SOU:
			return _resolve_attack(rounded_base, "melee", apply)
		Tile.Suit.PIN:
			return _resolve_attack(rounded_base, "ranged", apply)
	return {}


func _resolve_attack(base_attack: int, attack_type: String, apply: bool) -> Dictionary:
	var bonus := 1.0
	if attack_type == "melee" and enemy_army_defense > 0:
		bonus = ARMY_BREAK_BONUS
	elif attack_type == "ranged" and enemy_army_defense <= 0:
		bonus = CITY_BREAK_BONUS

	var effective_attack := int(round(base_attack * bonus))
	var remaining := effective_attack
	var army_damage: int = min(enemy_army_defense, remaining)
	remaining -= army_damage
	var city_damage: int = min(enemy_city_defense, max(remaining, 0))

	if apply:
		enemy_army_defense = max(enemy_army_defense - army_damage, 0)
		enemy_city_defense = max(enemy_city_defense - city_damage, 0)

	return {
		"type": attack_type,
		"value": army_damage + city_damage,
		"base_value": base_attack,
		"effective_value": effective_attack,
		"army_damage": army_damage,
		"city_damage": city_damage,
		"bonus": bonus,
	}


func _scoring_tiles_for_play(play: Dictionary, tiles: Array) -> Array:
	var id := str(play.get("id", ""))
	if id == "pass":
		return []
	if id == "scattered":
		var best_tile: Tile = null
		var best_value := -1
		for tile in tiles:
			var value := tile_point(tile)
			if value > best_value:
				best_value = value
				best_tile = tile
		return [best_tile] if best_tile != null and best_value > 0 else []
	return tiles


func _score_tiles(tiles: Array) -> int:
	var score := 0
	for tile in tiles:
		score += tile_point(tile)
	return score


func _play_multiplier(play_id: String) -> float:
	match play_id:
		"single":
			return SINGLE_MULTIPLIER
		"scattered":
			return SCATTERED_MULTIPLIER
		"pair":
			return PAIR_MULTIPLIER
		"sequence":
			return SEQUENCE_MULTIPLIER
		"triplet":
			return TRIPLET_MULTIPLIER
		"kan":
			return KAN_MULTIPLIER
	return 0.0


func _enters_battlefield(play: Dictionary) -> bool:
	var id := str(play.get("id", ""))
	return id == "sequence" or id == "triplet" or id == "kan"


func _regular_play_count_for(play: Dictionary, tiles: Array) -> int:
	if str(play.get("id", "")) == "kan":
		return MAX_PLAY_PER_TURN
	return min(tiles.size(), MAX_PLAY_PER_TURN)


func _build_hu_components(breakdown: Dictionary) -> Array[Dictionary]:
	var components: Array[Dictionary] = []
	for meld in breakdown.get("battlefield_melds", []) as Array:
		var meld_tiles := _tiles_from_play(meld)
		if meld_tiles.is_empty():
			continue
		components.append({
			"source": "battlefield",
			"tiles": meld_tiles,
			"weight": BATTLEFIELD_WIN_WEIGHT,
			"play_id": str(meld.get("id", "")),
		})
	for meld_tiles in breakdown.get("concealed_melds", []) as Array:
		var play := classify_play(meld_tiles)
		components.append({
			"source": "hand",
			"tiles": meld_tiles,
			"weight": HAND_WIN_WEIGHT,
			"play_id": str(play.get("id", "")),
		})
	var pair_tiles: Array = breakdown.get("pair", []) as Array
	if not pair_tiles.is_empty():
		components.append({
			"source": "pair",
			"tiles": pair_tiles,
			"weight": 1.0,
			"play_id": "win_pair",
		})
	return components


func _ordered_hu_components(components: Array[Dictionary]) -> Array[Dictionary]:
	var ordered := components.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var suit_order_a := _hu_suit_order(_component_suit(a))
		var suit_order_b := _hu_suit_order(_component_suit(b))
		if suit_order_a != suit_order_b:
			return suit_order_a < suit_order_b
		return _hu_source_order(str(a.get("source", ""))) < _hu_source_order(str(b.get("source", "")))
	)
	return ordered


func _component_suit(component: Dictionary) -> int:
	var tiles: Array = component.get("tiles", []) as Array
	if tiles.is_empty():
		return -1
	return int(tiles[0].suit)


func _hu_suit_order(suit: int) -> int:
	match suit:
		Tile.Suit.SOU:
			return 0
		Tile.Suit.PIN:
			return 1
		Tile.Suit.MAN:
			return 2
	return 3


func _hu_source_order(source: String) -> int:
	match source:
		"battlefield":
			return 0
		"hand":
			return 1
		"pair":
			return 2
	return 3


func _reset_after_hu() -> void:
	hand.clear()
	hand.add_tiles(wall.draw(INITIAL_HAND_SIZE))
	hand.sort_in_place()
	open_melds.clear()
	last_regular_play_count = 0
	last_action_was_kan = false


func _enemy_attack() -> Dictionary:
	var defense_before := player_army_defense
	var blocked: int = min(player_army_defense, enemy_attack)
	var hp_damage: int = max(enemy_attack - player_army_defense, 0)
	player_general_hp = max(player_general_hp - hp_damage, 0)
	player_army_defense = 0
	return {
		"blocked": blocked,
		"hp_damage": hp_damage,
		"attack": enemy_attack,
		"defense_before": defense_before,
		"defense_after": player_army_defense,
	}


func _check_battle_result() -> bool:
	if enemy_city_defense <= 0:
		enemy_city_defense = 0
		is_complete = true
		result = BattleResult.WIN
		return true
	if player_general_hp <= 0:
		player_general_hp = 0
		is_complete = true
		result = BattleResult.LOSE
		return true
	return false


func _selections_are_unique_and_valid(selections: Array) -> bool:
	var keys := {}
	for selection in selections:
		var zone := int(selection.get("zone", -1))
		var index := int(selection.get("index", -1))
		if not can_select(zone, index):
			return false
		var key := "%d:%d" % [zone, index]
		if keys.has(key):
			return false
		keys[key] = true
	return true


func _tiles_from_selections(selections: Array) -> Array:
	var tiles := []
	for selection in selections:
		var zone := int(selection.get("zone", -1))
		var index := int(selection.get("index", -1))
		if zone == TileZone.DRAW:
			tiles.append(drawn[index])
		elif zone == TileZone.OPENING:
			tiles.append(opening_choices[index])
		else:
			tiles.append(hand.tiles[index])
	return tiles


func _remove_selected_tiles(selections: Array, add_to_discard: bool) -> void:
	var hand_indices: Array[int] = []
	var draw_indices: Array[int] = []
	for selection in selections:
		var zone := int(selection.get("zone", -1))
		var index := int(selection.get("index", -1))
		if zone == TileZone.HAND:
			hand_indices.append(index)
		elif zone == TileZone.DRAW:
			draw_indices.append(index)

	hand_indices.sort()
	hand_indices.reverse()
	for index in hand_indices:
		if add_to_discard:
			discard_pile.append(hand.tiles[index])
		hand.tiles.remove_at(index)

	draw_indices.sort()
	draw_indices.reverse()
	for index in draw_indices:
		if add_to_discard:
			discard_pile.append(drawn[index])
		drawn.remove_at(index)


func _find_concealed_breakdown(tiles: Array, required_melds: int) -> Dictionary:
	if required_melds < 0:
		return {}
	var counts := _counts_by_key(tiles)
	for key in counts.keys():
		if int(counts[key]) < 2:
			continue
		var pair := _take_tiles_by_key(tiles, key, 2)
		var remaining := _remove_tiles_by_key(tiles, key, 2)
		var melds := _find_n_melds(remaining, required_melds)
		if melds.size() == required_melds:
			return {"pair": pair, "concealed_melds": melds}
	return {}


func _find_n_melds(tiles: Array, needed: int) -> Array:
	if needed == 0:
		return []
	if tiles.size() < needed * 3:
		return []
	var candidates := _all_meld_candidates(tiles)
	for candidate in candidates:
		var remaining := _subtract_tiles(tiles, candidate)
		var rest := _find_n_melds(remaining, needed - 1)
		if needed - 1 == 0 or not rest.is_empty():
			var result := [candidate]
			result.append_array(rest)
			return result
	return []


func _all_meld_candidates(tiles: Array) -> Array:
	var candidates := []
	for i in range(tiles.size()):
		for j in range(i + 1, tiles.size()):
			for k in range(j + 1, tiles.size()):
				var candidate := [tiles[i], tiles[j], tiles[k]]
				if PatternMatcher.is_triplet(candidate) or PatternMatcher.is_sequence(candidate):
					candidates.append(candidate)
	return candidates


func _subtract_tiles(tiles: Array, remove_tiles: Array) -> Array:
	var result := tiles.duplicate()
	for selected in remove_tiles:
		for i in range(result.size()):
			if result[i].equals_tile(selected):
				result.remove_at(i)
				break
	return result


func _counts_by_key(tiles: Array) -> Dictionary:
	var counts := {}
	for tile in tiles:
		counts[tile.key()] = int(counts.get(tile.key(), 0)) + 1
	return counts


func _take_tiles_by_key(tiles: Array, key: String, count: int) -> Array:
	var result := []
	for tile in tiles:
		if tile.key() == key:
			result.append(tile)
			if result.size() >= count:
				break
	return result


func _remove_tiles_by_key(tiles: Array, key: String, count: int) -> Array:
	var result := tiles.duplicate()
	var removed := 0
	for i in range(result.size() - 1, -1, -1):
		if result[i].key() == key:
			result.remove_at(i)
			removed += 1
			if removed >= count:
				break
	return result


func _tiles_from_play(play: Dictionary) -> Array:
	if play.has("tile_objects"):
		return play.get("tile_objects", []) as Array
	return []


func _duplicate_tiles(tiles: Array) -> Array:
	var copies := []
	for tile in tiles:
		copies.append(tile.duplicate_tile())
	return copies


func _primary_effect_type(effects: Array) -> String:
	if effects.is_empty():
		return "none"
	return str(effects[0].get("type", "none"))


func _primary_effect_value(effects: Array) -> int:
	if effects.is_empty():
		return 0
	return int(effects[0].get("value", 0))


func _effects_to_text(effects: Array) -> String:
	if effects.is_empty():
		return "No v1 effect"
	var parts: Array[String] = []
	for effect in effects:
		var effect_type := str(effect.get("type", "none"))
		match effect_type:
			"melee":
				parts.append("Melee -%d army -%d city" % [int(effect.get("army_damage", 0)), int(effect.get("city_damage", 0))])
			"ranged":
				parts.append("Ranged -%d army -%d city" % [int(effect.get("army_damage", 0)), int(effect.get("city_damage", 0))])
			"army_defense":
				parts.append("Army DEF +%d" % int(effect.get("value", 0)))
	return ", ".join(parts) if not parts.is_empty() else "No v1 effect"


func _play_event_text(play: Dictionary, effects: Array) -> String:
	if str(play.get("id", "")) == "pass":
		return "Passed."
	return "%s played: %s." % [str(play.get("name", "Set")), _effects_to_text(effects)]


func _tile_names(tiles: Array) -> Array[String]:
	var names: Array[String] = []
	for tile in tiles:
		names.append(tile.display_name())
	return names


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}
