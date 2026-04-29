class_name PatternMatcher
extends RefCounted

const PATTERNS := [
	{"id": "kan", "name": "杠", "stage": "1.0", "tile_count": 4, "mult": 8.0},
	{"id": "triplet", "name": "刻子", "stage": "1.0", "tile_count": 3, "mult": 5.0},
	{"id": "sequence", "name": "顺子", "stage": "1.0", "tile_count": 3, "mult": 4.0},
	{"id": "pair", "name": "对子", "stage": "1.0", "tile_count": 2, "mult": 2.5},
	{"id": "single", "name": "单张", "stage": "1.0", "tile_count": 1, "mult": 1.0},
]


static func match_pattern(selected_tiles: Array) -> Dictionary:
	if selected_tiles.is_empty() or selected_tiles.size() > 9:
		return {}

	var tiles := _sorted_copy(selected_tiles)
	for pattern in PATTERNS:
		if _matches(pattern.get("id", ""), tiles):
			return pattern.duplicate()
	return {}


static func is_standard_win(tiles: Array) -> bool:
	if tiles.size() != 14:
		return false

	var counts := _counts_by_tile(tiles)
	for pair_key in counts.keys():
		if counts[pair_key] < 2:
			continue
		var remaining := _remove_tile_key_count(tiles, pair_key, 2)
		if _can_split_all_melds(remaining):
			return true
	return false


static func _matches(pattern_id: String, tiles: Array) -> bool:
	match pattern_id:
		"yakuman":
			return is_yakuman(tiles)
		"chinitsu_group":
			return is_chinitsu_group(tiles)
		"iitsu":
			return is_iitsu(tiles)
		"kan":
			return is_kan(tiles)
		"iipeikou":
			return is_iipeikou(tiles)
		"sanshoku_set":
			return is_sanshoku_set(tiles)
		"two_pairs":
			return is_two_pairs(tiles)
		"sequence":
			return is_sequence(tiles)
		"triplet":
			return is_triplet(tiles)
		"taatsu":
			return is_taatsu(tiles)
		"pair":
			return is_pair(tiles)
		"single":
			return tiles.size() == 1
	return false


static func is_pair(tiles: Array) -> bool:
	return tiles.size() == 2 and _all_same_tile(tiles)


static func is_taatsu(tiles: Array) -> bool:
	return tiles.size() == 2 and _all_same_suited_suit(tiles) and abs(tiles[0].rank - tiles[1].rank) == 1


static func is_triplet(tiles: Array) -> bool:
	return tiles.size() == 3 and _all_same_tile(tiles)


static func is_sequence(tiles: Array) -> bool:
	if tiles.size() != 3 or not _all_same_suited_suit(tiles):
		return false
	var ranks := _ranks(tiles)
	ranks.sort()
	return ranks[0] + 1 == ranks[1] and ranks[1] + 1 == ranks[2]


static func is_two_pairs(tiles: Array) -> bool:
	if tiles.size() != 4:
		return false
	var counts := _counts_by_tile(tiles)
	if counts.size() != 2:
		return false
	for count in counts.values():
		if count != 2:
			return false
	return true


static func is_sanshoku_set(tiles: Array) -> bool:
	if tiles.size() != 3:
		return false
	var rank: int = tiles[0].rank
	var suits := {}
	for tile in tiles:
		if not tile.is_suited():
			return false
		if tile.rank != rank:
			return false
		suits[tile.suit] = true
	return suits.size() == 3


static func is_iipeikou(tiles: Array) -> bool:
	if tiles.size() != 6 or not _all_same_suited_suit(tiles):
		return false
	var counts_by_rank := _counts_by_rank(tiles)
	if counts_by_rank.size() != 3:
		return false
	var ranks := counts_by_rank.keys()
	ranks.sort()
	if not (ranks[0] + 1 == ranks[1] and ranks[1] + 1 == ranks[2]):
		return false
	for count in counts_by_rank.values():
		if count != 2:
			return false
	return true


static func is_kan(tiles: Array) -> bool:
	return tiles.size() == 4 and _all_same_tile(tiles)


static func is_iitsu(tiles: Array) -> bool:
	if tiles.size() != 9 or not _all_same_suited_suit(tiles):
		return false
	var ranks := _ranks(tiles)
	ranks.sort()
	return _arrays_equal(ranks, [1, 2, 3, 4, 5, 6, 7, 8, 9])


static func is_chinitsu_group(tiles: Array) -> bool:
	return tiles.size() == 5 and _all_same_suited_suit(tiles)


static func is_yakuman(tiles: Array) -> bool:
	if tiles.size() != 7:
		return false

	var counts := _counts_by_tile(tiles)
	var pair_keys: Array[String] = []
	for key in counts:
		if counts[key] >= 2:
			pair_keys.append(key)

	for pair_key in pair_keys:
		var remaining := _remove_tile_key_count(tiles, pair_key, 2)
		if _contains_meld_plus_taatsu_or_pair(remaining):
			return true
	return false


static func _contains_meld_plus_taatsu_or_pair(tiles: Array) -> bool:
	for meld in _all_three_tile_subsets(tiles):
		if is_sequence(meld) or is_triplet(meld):
			var remaining := _subtract_subset(tiles, meld)
			if is_pair(remaining) or is_taatsu(remaining):
				return true
	return false


static func _all_three_tile_subsets(tiles: Array) -> Array:
	var subsets := []
	for i in range(tiles.size()):
		for j in range(i + 1, tiles.size()):
			for k in range(j + 1, tiles.size()):
				subsets.append([tiles[i], tiles[j], tiles[k]])
	return subsets


static func _subtract_subset(tiles: Array, subset: Array) -> Array:
	var result := tiles.duplicate()
	for selected in subset:
		for i in range(result.size()):
			if result[i].equals_tile(selected):
				result.remove_at(i)
				break
	return result


static func _remove_tile_key_count(tiles: Array, key: String, count: int) -> Array:
	var result := tiles.duplicate()
	var removed := 0
	for i in range(result.size() - 1, -1, -1):
		if result[i].key() == key:
			result.remove_at(i)
			removed += 1
			if removed >= count:
				break
	return result


static func _all_same_tile(tiles: Array) -> bool:
	if tiles.is_empty():
		return false
	var key: String = tiles[0].key()
	for tile in tiles:
		if tile.key() != key:
			return false
	return true


static func _all_same_suit(tiles: Array) -> bool:
	if tiles.is_empty():
		return false
	var suit: int = tiles[0].suit
	for tile in tiles:
		if tile.suit != suit:
			return false
	return true


static func _all_same_suited_suit(tiles: Array) -> bool:
	return _all_same_suit(tiles) and tiles[0].is_suited()


static func _can_split_all_melds(tiles: Array) -> bool:
	if tiles.is_empty():
		return true
	var sorted_tiles := _sorted_copy(tiles)
	var first: Tile = sorted_tiles[0]

	var triplet := [first, first, first]
	if _contains_tiles(sorted_tiles, triplet):
		if _can_split_all_melds(_subtract_subset(sorted_tiles, triplet)):
			return true

	if first.is_suited() and first.rank <= 7:
		var sequence := [first, Tile.new(first.suit, first.rank + 1), Tile.new(first.suit, first.rank + 2)]
		if _contains_tiles(sorted_tiles, sequence):
			if _can_split_all_melds(_subtract_subset(sorted_tiles, sequence)):
				return true

	return false


static func _contains_tiles(tiles: Array, selected_tiles: Array) -> bool:
	var remaining := tiles.duplicate()
	for selected in selected_tiles:
		var found_index := -1
		for i in range(remaining.size()):
			if remaining[i].equals_tile(selected):
				found_index = i
				break
		if found_index == -1:
			return false
		remaining.remove_at(found_index)
	return true


static func _counts_by_tile(tiles: Array) -> Dictionary:
	var counts := {}
	for tile in tiles:
		counts[tile.key()] = counts.get(tile.key(), 0) + 1
	return counts


static func _counts_by_rank(tiles: Array) -> Dictionary:
	var counts := {}
	for tile in tiles:
		counts[tile.rank] = counts.get(tile.rank, 0) + 1
	return counts


static func _ranks(tiles: Array) -> Array:
	var ranks := []
	for tile in tiles:
		ranks.append(tile.rank)
	return ranks


static func _sorted_copy(tiles: Array) -> Array:
	var copy := tiles.duplicate()
	copy.sort_custom(func(a: Tile, b: Tile) -> bool: return a.compare_to(b) < 0)
	return copy


static func _arrays_equal(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	for i in range(left.size()):
		if left[i] != right[i]:
			return false
	return true
