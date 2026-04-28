class_name DuelBattleState
extends RefCounted

const OPENING_DRAW_SIZE := 16
const INITIAL_HAND_SIZE := 13
const ACTIVE_HAND_SIZE := 16
const OPENING_DISCARD_SIZE := 3
const DRAW_PER_TURN := 3
const PLAY_PER_TURN := 3
const ENEMY_ATTACK_INTERVAL := 3
const DEFAULT_PLAYER_HP := 100
const DEFAULT_ENEMY_HP := 160
const DEFAULT_ENEMY_ATTACK := 24
const BASE_EFFECT_VALUE := 10
const WEAK_EFFECT_VALUE := 20
const STRONG_EFFECT_VALUE := 30
const BASE_WIN_MULTIPLIER := 2.0
const CONCEALED_MELD_MULT_BONUS := 0.5
const OPEN_MELD_MULT_BONUS := 0.25
const LOW_HP_MULT_BONUS := 0.5
const ATTACK_COUNTDOWN_MULT_BONUS := 0.5

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
var scatter_ledger: Array[Dictionary] = []
var turn_number := 1
var player_turns_taken := 0
var enemy_attack_countdown := ENEMY_ATTACK_INTERVAL
var player_hp := DEFAULT_PLAYER_HP
var player_defense := 0
var money := 0
var tempo := 0
var enemy_hp := DEFAULT_ENEMY_HP
var enemy_attack := DEFAULT_ENEMY_ATTACK
var is_complete := false
var result := BattleResult.ONGOING
var last_event := ""
var last_play_preview := {}


func start_run(seed: int = 0, auto_choose_opening: bool = true) -> void:
	wall = MahjongWall.new(false)
	wall.reset(true, seed, true)
	hand = Hand.new(ACTIVE_HAND_SIZE)
	opening_choices = wall.draw(OPENING_DRAW_SIZE)
	drawn.clear()
	discard_pile.clear()
	open_melds.clear()
	played_sets.clear()
	scatter_ledger.clear()
	turn_number = 1
	player_turns_taken = 0
	enemy_attack_countdown = ENEMY_ATTACK_INTERVAL
	player_hp = DEFAULT_PLAYER_HP
	player_defense = 0
	money = 0
	tempo = 0
	enemy_hp = DEFAULT_ENEMY_HP
	enemy_attack = DEFAULT_ENEMY_ATTACK
	is_complete = false
	result = BattleResult.ONGOING
	last_event = "Choose 13 from 16"
	last_play_preview.clear()
	if auto_choose_opening:
		var indices: Array[int] = []
		for i in range(INITIAL_HAND_SIZE):
			indices.append(i)
		choose_initial_hand(indices)


func choose_initial_hand(indices: Array[int]) -> Dictionary:
	if indices.size() != INITIAL_HAND_SIZE:
		return _invalid("choose_thirteen")
	var used := {}
	for index in indices:
		if index < 0 or index >= opening_choices.size() or used.has(index):
			return _invalid("invalid_opening_selection")
		used[index] = true

	hand.clear()
	for i in range(opening_choices.size()):
		if used.has(i):
			hand.add_tile(opening_choices[i])
		else:
			discard_pile.append(opening_choices[i])
	opening_choices.clear()
	hand.sort_in_place()
	_draw_candidates()
	last_event = "Opening kept 13, discarded 3"
	return {"valid": true, "event": last_event}


func accept_drawn_into_hand() -> void:
	for tile in drawn:
		hand.add_tile(tile)
	drawn.clear()
	hand.sort_in_place()


func can_select(zone: int, index: int) -> bool:
	if zone == TileZone.DRAW:
		return index >= 0 and index < drawn.size()
	if zone == TileZone.OPENING:
		return index >= 0 and index < opening_choices.size()
	return index >= 0 and index < hand.size()


func preview_play(selections: Array) -> Dictionary:
	if selections.size() != PLAY_PER_TURN:
		return _invalid("play_exactly_three")
	if not _selections_are_unique_and_valid(selections):
		return _invalid("invalid_selection")
	var tiles := _tiles_from_selections(selections)
	var play := classify_play(tiles)
	var preview := play.duplicate(true)
	preview["effects"] = _preview_effects(play, tiles)
	return {"valid": true, "play": preview}


func play_tiles(selections: Array) -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	if selections.size() != PLAY_PER_TURN:
		return _invalid("play_exactly_three")
	if not _selections_are_unique_and_valid(selections):
		return _invalid("invalid_selection")

	var tiles := _tiles_from_selections(selections)
	var play := classify_play(tiles)
	var effects := _apply_play_effects(play, tiles)
	play["effects"] = effects
	play["effect_type"] = _primary_effect_type(effects)
	play["effect_value"] = _primary_effect_value(effects)
	play["tiles"] = _tile_names(tiles)
	played_sets.append(play)
	last_play_preview = play.duplicate(true)

	if play.get("id", "") == "sequence" or play.get("id", "") == "triplet":
		open_melds.append(play)
	elif play.get("id", "") == "scattered":
		scatter_ledger.append(play)

	_remove_selected_tiles(selections, false)
	for tile in drawn:
		hand.add_tile(tile)
	drawn.clear()
	hand.sort_in_place()

	player_turns_taken += 1
	enemy_attack_countdown -= 1
	var enemy_attack_event := {}
	if enemy_attack_countdown <= 0:
		enemy_attack_event = _enemy_attack()
		enemy_attack_countdown = ENEMY_ATTACK_INTERVAL

	_check_battle_result()
	if not is_complete:
		turn_number += 1
		_draw_candidates()

	last_event = "%s played: %s" % [str(play.get("name", "Set")), _effects_to_text(effects)]
	return {"valid": true, "play": play.duplicate(true), "enemy_attack": enemy_attack_event, "event": last_event}


func play_meld(selections: Array) -> Dictionary:
	return play_tiles(selections)


func can_ultimate_win() -> bool:
	return not get_win_breakdown().is_empty()


func get_win_breakdown() -> Dictionary:
	if hand == null:
		return {}
	var open_count: int = min(open_melds.size(), 4)
	var required_concealed: int = max(0, 4 - open_count)
	return _find_concealed_breakdown(hand.tiles, required_concealed)


func current_win_multiplier() -> float:
	var breakdown := get_win_breakdown()
	if breakdown.is_empty():
		return BASE_WIN_MULTIPLIER
	var concealed_count := int((breakdown.get("concealed_melds", []) as Array).size())
	var open_count: int = min(open_melds.size(), 4)
	var multiplier := BASE_WIN_MULTIPLIER
	multiplier += concealed_count * CONCEALED_MELD_MULT_BONUS
	multiplier += open_count * OPEN_MELD_MULT_BONUS
	if player_hp < int(DEFAULT_PLAYER_HP * 0.3):
		multiplier += LOW_HP_MULT_BONUS
	if enemy_attack_countdown == 1:
		multiplier += ATTACK_COUNTDOWN_MULT_BONUS
	return multiplier


func ultimate_win() -> Dictionary:
	if is_complete:
		return _invalid("battle_complete")
	var breakdown := get_win_breakdown()
	if breakdown.is_empty():
		return _invalid("not_ready")

	var totals := {"damage": 0.0, "defense": 0.0, "money": 0.0, "tempo": 0.0}
	for meld in open_melds:
		_add_resource_totals(totals, _resource_for_suit(int(meld.get("suit", -1))), STRONG_EFFECT_VALUE, 1.0)
	for meld_tiles in breakdown.get("concealed_melds", []):
		_add_resource_totals(totals, _resource_for_tile(meld_tiles[0]), STRONG_EFFECT_VALUE, 1.5)
	var pair_tiles: Array = breakdown.get("pair", [])
	if not pair_tiles.is_empty():
		_add_resource_totals(totals, _resource_for_tile(pair_tiles[0]), WEAK_EFFECT_VALUE, 1.0)
	for scattered in scatter_ledger:
		var resource := str(scattered.get("triggered_resource", "none"))
		_add_resource_totals(totals, resource, BASE_EFFECT_VALUE, 0.5)

	var multiplier := current_win_multiplier()
	var damage := int(round(float(totals.get("damage", 0.0)) * multiplier))
	var defense_gain := int(round(float(totals.get("defense", 0.0)) * multiplier))
	var money_gain := int(round(float(totals.get("money", 0.0)) * multiplier))
	var tempo_gain := int(round(float(totals.get("tempo", 0.0)) * multiplier))

	enemy_hp = max(enemy_hp - damage, 0)
	player_defense += defense_gain
	money += money_gain
	if tempo_gain > 0:
		tempo += tempo_gain
		enemy_attack_countdown += tempo_gain

	last_event = "ULTIMATE WIN: %d damage, +%d defense, +$%d" % [damage, defense_gain, money_gain]
	_check_battle_result()
	return {
		"valid": true,
		"damage": damage,
		"defense": defense_gain,
		"money": money_gain,
		"tempo": tempo_gain,
		"multiplier": multiplier,
		"breakdown": breakdown,
		"event": last_event,
	}


func remaining_deck() -> int:
	return wall.remaining_count() if wall != null else 0


static func classify_play(tiles: Array) -> Dictionary:
	if tiles.size() == 3 and PatternMatcher.is_triplet(tiles):
		return {"id": "triplet", "name": "Triplet", "tile_count": 3, "suit": tiles[0].suit, "open_meld": true}
	if tiles.size() == 3 and PatternMatcher.is_sequence(tiles):
		return {"id": "sequence", "name": "Sequence", "tile_count": 3, "suit": tiles[0].suit, "open_meld": true}
	var pair_info := _pair_and_single(tiles)
	if not pair_info.is_empty():
		return {"id": "pair_single", "name": "Pair + Single", "tile_count": 3, "open_meld": false, "pair_tile": pair_info.get("pair_tile"), "single_tile": pair_info.get("single_tile")}
	return {"id": "scattered", "name": "Scattered", "tile_count": 3, "open_meld": false}


static func classify_meld(tiles: Array) -> Dictionary:
	var play := classify_play(tiles)
	if play.get("id", "") == "sequence" or play.get("id", "") == "triplet":
		return play
	return {}


func _draw_candidates() -> void:
	drawn = wall.draw(DRAW_PER_TURN)


func _preview_effects(play: Dictionary, tiles: Array) -> Array[Dictionary]:
	return _build_effects(play, tiles, false)


func _apply_play_effects(play: Dictionary, tiles: Array) -> Array[Dictionary]:
	var effects := _build_effects(play, tiles, true)
	if play.get("id", "") == "scattered" and not effects.is_empty():
		play["triggered_resource"] = effects[0].get("type", "none")
	return effects


func _build_effects(play: Dictionary, tiles: Array, apply: bool) -> Array[Dictionary]:
	var id := str(play.get("id", ""))
	match id:
		"sequence":
			return [_make_effect(_resource_for_suit(int(play.get("suit", -1))), STRONG_EFFECT_VALUE, apply)]
		"triplet":
			return [_make_effect(_resource_for_tile(tiles[0]), STRONG_EFFECT_VALUE, apply)]
		"pair_single":
			var pair_tile: Tile = play.get("pair_tile")
			var single_tile: Tile = play.get("single_tile")
			return [
				_make_effect(_resource_for_tile(pair_tile), WEAK_EFFECT_VALUE, apply),
				_make_effect(_resource_for_tile(single_tile), BASE_EFFECT_VALUE, apply),
			]
		"scattered":
			return []
	return []


func _make_effect(resource: String, value: int, apply: bool) -> Dictionary:
	if apply:
		match resource:
			"damage":
				enemy_hp = max(enemy_hp - value, 0)
			"defense":
				player_defense += value
			"money":
				money += value
			"tempo":
				tempo += value
				enemy_attack_countdown += max(1, int(round(value / float(BASE_EFFECT_VALUE))))
	return {"type": resource, "value": value}


func _resource_for_tile(tile: Tile) -> String:
	if tile == null:
		return "none"
	if tile.suit == Tile.Suit.DRAGON:
		match tile.rank:
			1:
				return "damage"
			2:
				return "money"
			3:
				return "defense"
	if tile.suit == Tile.Suit.WIND:
		return "tempo"
	return _resource_for_suit(tile.suit)


func _resource_for_suit(suit: int) -> String:
	match suit:
		Tile.Suit.MAN:
			return "money"
		Tile.Suit.SOU:
			return "damage"
		Tile.Suit.PIN:
			return "defense"
		Tile.Suit.WIND:
			return "tempo"
	return "none"


func _enemy_attack() -> Dictionary:
	var blocked: int = min(player_defense, enemy_attack)
	player_defense = max(player_defense - enemy_attack, 0)
	var hp_damage := enemy_attack - blocked
	player_hp = max(player_hp - hp_damage, 0)
	return {"blocked": blocked, "hp_damage": hp_damage, "attack": enemy_attack}


func _check_battle_result() -> bool:
	if enemy_hp <= 0:
		enemy_hp = 0
		is_complete = true
		result = BattleResult.WIN
		return true
	if player_hp <= 0:
		player_hp = 0
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


static func _pair_and_single(tiles: Array) -> Dictionary:
	if tiles.size() != 3:
		return {}
	for i in range(tiles.size()):
		for j in range(i + 1, tiles.size()):
			if tiles[i].equals_tile(tiles[j]):
				for k in range(tiles.size()):
					if k != i and k != j:
						return {"pair_tile": tiles[i], "single_tile": tiles[k]}
	return {}


func _add_resource_totals(totals: Dictionary, resource: String, value: int, weight: float) -> void:
	if not totals.has(resource):
		return
	totals[resource] = float(totals.get(resource, 0.0)) + value * weight


func _primary_effect_type(effects: Array) -> String:
	for effect in effects:
		if str(effect.get("type", "none")) == "damage":
			return "damage"
	for effect in effects:
		if str(effect.get("type", "none")) != "none":
			return str(effect.get("type", "none"))
	return "none"


func _primary_effect_value(effects: Array) -> int:
	for effect in effects:
		if str(effect.get("type", "none")) == "damage":
			return int(effect.get("value", 0))
	if effects.is_empty():
		return 0
	return int(effects[0].get("value", 0))


func _effects_to_text(effects: Array) -> String:
	var parts: Array[String] = []
	for effect in effects:
		var resource := str(effect.get("type", "none")).capitalize()
		var value := int(effect.get("value", 0))
		parts.append("%s %+d" % [resource, value])
	return ", ".join(parts)


func _tile_names(tiles: Array) -> Array[String]:
	var names: Array[String] = []
	for tile in tiles:
		names.append(tile.display_name())
	return names


func _invalid(reason: String) -> Dictionary:
	return {"valid": false, "reason": reason}
