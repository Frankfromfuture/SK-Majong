extends GutTest

const TileScript = preload("res://src/core/tile.gd")
const PatternMatcherScript = preload("res://src/core/pattern_matcher.gd")
const ScorerScript = preload("res://src/core/scorer.gd")


func test_score_uses_base_score_times_pattern_multiplier() -> void:
	var pattern := PatternMatcherScript.match_pattern([m(1), m(2), m(3)])
	var score := ScorerScript.score(pattern)
	assert_eq(score.get("final_score", -1), 60)
	assert_eq(score.get("pattern_id", ""), "sequence")


func test_score_applies_added_score_before_multiplier() -> void:
	var pattern := PatternMatcherScript.match_pattern([m(1), m(2), m(3)])
	var score := ScorerScript.score(pattern, 30, 1.0)
	assert_eq(score.get("final_score", -1), 120)


func test_score_applies_general_multiplier_after_pattern_multiplier() -> void:
	var pattern := PatternMatcherScript.match_pattern([m(1), m(1), m(1), m(1)])
	var score := ScorerScript.score(pattern, 200, 2.0)
	assert_eq(score.get("final_score", -1), 2400)


func test_empty_pattern_scores_zero() -> void:
	var score := ScorerScript.score({})
	assert_eq(score.get("final_score", -1), 0)
	assert_eq(score.get("pattern_id", ""), "")


func test_rounds_fractional_modifiers_to_integer_score() -> void:
	var pattern := PatternMatcherScript.match_pattern([m(5), m(5)])
	var score := ScorerScript.score(pattern, 0, 1.5)
	assert_eq(score.get("final_score", -1), 15)


func m(rank: int) -> Tile:
	return TileScript.man(rank)
