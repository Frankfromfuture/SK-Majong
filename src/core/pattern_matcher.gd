class_name PatternMatcher
extends RefCounted

const PATTERNS := [
	{"id": "yakuman", "name": "役满", "level": 12, "base_score": 500, "mult": 10.0, "tile_count": 7},
	{"id": "chinitsu_group", "name": "清一色组", "level": 11, "base_score": 200, "mult": 6.0, "tile_count": 5},
	{"id": "iitsu", "name": "一气通贯", "level": 10, "base_score": 150, "mult": 5.0, "tile_count": 9},
	{"id": "kan", "name": "杠", "level": 9, "base_score": 100, "mult": 4.0, "tile_count": 4},
	{"id": "iipeikou", "name": "一杯口", "level": 8, "base_score": 80, "mult": 3.0, "tile_count": 6},
	{"id": "sanshoku_set", "name": "三色搭", "level": 7, "base_score": 50, "mult": 3.0, "tile_count": 3},
	{"id": "two_pairs", "name": "两对", "level": 6, "base_score": 40, "mult": 2.0, "tile_count": 4},
	{"id": "sequence", "name": "顺子", "level": 5, "base_score": 30, "mult": 2.0, "tile_count": 3},
	{"id": "triplet", "name": "刻子", "level": 4, "base_score": 30, "mult": 2.0, "tile_count": 3},
	{"id": "taatsu", "name": "搭子", "level": 3, "base_score": 15, "mult": 1.0, "tile_count": 2},
	{"id": "pair", "name": "对儿", "level": 2, "base_score": 10, "mult": 1.0, "tile_count": 2},
	{"id": "single", "name": "单骑", "level": 1, "base_score": 5, "mult": 1.0, "tile_count": 1},
]


static func match_pattern(selected_tiles: Array) -> Dictionary:
	if selected_tiles.is_empty() or selected_tiles.size() > 9:
		return {}

	var tiles := _sorted_copy(selected_tiles)
	for pattern in PATTERNS:
		if _matches(pattern.get("id", ""), tiles):
			return pattern.duplicate()
	return {}


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
	return tiles.size() == 2 and _all_same_suit(tiles) and abs(tiles[0].rank - tiles[1].rank) == 1


static func is_triplet(tiles: Array) -> bool:
	return tiles.size() == 3 and _all_same_tile(tiles)


static func is_sequence(tiles: Array) -> bool:
	if tiles.size() != 3 or not _all_same_suit(tiles):
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
		if tile.rank != rank:
			return false
		suits[tile.suit] = true
	return suits.size() == 3


static func is_iipeikou(tiles: Array) -> bool:
	if tiles.size() != 6 or not _all_same_suit(tiles):
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
	if tiles.size() != 9 or not _all_same_suit(tiles):
		return false
	var ranks := _ranks(tiles)
	ranks.sort()
	return _arrays_equal(ranks, [1, 2, 3, 4, 5, 6, 7, 8, 9])


static func is_chinitsu_group(tiles: Array) -> bool:
	return tiles.size() == 5 and _all_same_suit(tiles)


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
