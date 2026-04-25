extends GutTest

const TileScript = preload("res://src/core/tile.gd")
const PatternMatcherScript = preload("res://src/core/pattern_matcher.gd")


func test_all_patterns_have_at_least_five_positive_cases() -> void:
	var cases := {
		"single": [
			[m(1)], [m(9)], [p(5)], [s(1)], [s(9)],
		],
		"pair": [
			[m(1), m(1)], [m(9), m(9)], [p(5), p(5)], [s(1), s(1)], [s(8), s(8)],
		],
		"taatsu": [
			[m(1), m(2)], [m(8), m(9)], [p(4), p(5)], [s(6), s(7)], [p(2), p(3)],
		],
		"triplet": [
			[m(1), m(1), m(1)], [m(9), m(9), m(9)], [p(5), p(5), p(5)], [s(2), s(2), s(2)], [s(8), s(8), s(8)],
		],
		"sequence": [
			[m(1), m(2), m(3)], [m(7), m(8), m(9)], [p(4), p(5), p(6)], [s(2), s(3), s(4)], [s(6), s(7), s(8)],
		],
		"two_pairs": [
			[m(1), m(1), p(2), p(2)], [m(3), m(3), m(7), m(7)], [p(5), p(5), s(5), s(5)], [s(1), s(1), s(9), s(9)], [m(8), m(8), p(8), p(8)],
		],
		"sanshoku_set": [
			[m(1), p(1), s(1)], [m(2), p(2), s(2)], [m(5), p(5), s(5)], [m(8), p(8), s(8)], [m(9), p(9), s(9)],
		],
		"iipeikou": [
			[m(1), m(1), m(2), m(2), m(3), m(3)], [m(3), m(3), m(4), m(4), m(5), m(5)], [p(4), p(4), p(5), p(5), p(6), p(6)], [p(6), p(6), p(7), p(7), p(8), p(8)], [s(7), s(7), s(8), s(8), s(9), s(9)],
		],
		"kan": [
			[m(1), m(1), m(1), m(1)], [m(9), m(9), m(9), m(9)], [p(5), p(5), p(5), p(5)], [s(2), s(2), s(2), s(2)], [s(8), s(8), s(8), s(8)],
		],
		"iitsu": [
			[m(1), m(2), m(3), m(4), m(5), m(6), m(7), m(8), m(9)],
			[p(1), p(2), p(3), p(4), p(5), p(6), p(7), p(8), p(9)],
			[s(1), s(2), s(3), s(4), s(5), s(6), s(7), s(8), s(9)],
			[m(9), m(8), m(7), m(6), m(5), m(4), m(3), m(2), m(1)],
			[p(3), p(1), p(9), p(2), p(8), p(4), p(7), p(5), p(6)],
		],
		"chinitsu_group": [
			[m(1), m(3), m(5), m(7), m(9)], [m(1), m(2), m(3), m(4), m(5)], [p(2), p(2), p(5), p(8), p(9)], [s(1), s(4), s(4), s(6), s(9)], [p(3), p(4), p(6), p(7), p(8)],
		],
		"yakuman": [
			[m(1), m(1), p(2), p(3), p(4), s(8), s(9)],
			[m(2), m(2), m(5), m(5), m(5), p(7), p(7)],
			[p(9), p(9), s(1), s(2), s(3), m(4), m(5)],
			[s(3), s(3), p(7), p(7), p(7), m(1), m(1)],
			[m(4), m(4), m(6), m(7), m(8), s(5), s(6)],
		],
	}

	for expected_id in cases:
		assert_eq(cases[expected_id].size(), 5, "%s should have five positive cases" % expected_id)
		for tiles in cases[expected_id]:
			_assert_pattern(expected_id, tiles)


func test_key_priority_cases() -> void:
	_assert_pattern("single", [m(1)])
	_assert_pattern("chinitsu_group", [m(1), m(3), m(5), m(7), m(9)])
	_assert_pattern("iitsu", [m(1), m(2), m(3), m(4), m(5), m(6), m(7), m(8), m(9)])
	_assert_pattern("yakuman", [m(1), m(1), p(2), p(3), p(4), s(8), s(9)])


func test_invalid_or_unrelated_inputs_return_empty_dictionary() -> void:
	_assert_no_pattern([])
	_assert_no_pattern([m(1), p(2), s(3)])
	_assert_no_pattern([m(1), m(3)])
	_assert_no_pattern([m(1), p(1), p(1), s(2)])
	_assert_no_pattern([m(1), m(2), m(3), m(4), m(5), m(6), m(7), m(8), m(9), p(1)])


func test_near_misses_do_not_match_higher_patterns() -> void:
	_assert_pattern("sequence", [m(1), m(2), m(3)])
	_assert_pattern("triplet", [p(7), p(7), p(7)])
	_assert_no_pattern([m(1), m(2), m(4)])
	_assert_no_pattern([m(1), m(1), p(1)])
	_assert_no_pattern([m(1), m(1), m(2), m(2), m(4), m(4)])


func m(rank: int) -> Tile:
	return TileScript.man(rank)


func p(rank: int) -> Tile:
	return TileScript.pin(rank)


func s(rank: int) -> Tile:
	return TileScript.sou(rank)


func _assert_pattern(expected_id: String, tiles: Array) -> void:
	var result := PatternMatcherScript.match_pattern(tiles)
	assert_false(result.is_empty(), "Expected %s for %s" % [expected_id, _display(tiles)])
	assert_eq(result.get("id", ""), expected_id, "Wrong pattern for %s" % _display(tiles))


func _assert_no_pattern(tiles: Array) -> void:
	var result := PatternMatcherScript.match_pattern(tiles)
	assert_true(result.is_empty(), "Expected no pattern for %s, got %s" % [_display(tiles), result.get("id", "")])


func _display(tiles: Array) -> String:
	var names: Array[String] = []
	for tile in tiles:
		names.append(tile.display_name())
	return "[" + ", ".join(names) + "]"
