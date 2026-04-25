class_name Scorer
extends RefCounted


static func score(pattern_result: Dictionary, added_score: int = 0, multiplier_mod: float = 1.0) -> Dictionary:
	if pattern_result.is_empty():
		return {
			"pattern": "",
			"base_score": 0,
			"added_score": added_score,
			"pattern_mult": 0.0,
			"multiplier_mod": multiplier_mod,
			"final_score": 0,
		}

	var base_score := int(pattern_result.get("base_score", 0))
	var pattern_mult := float(pattern_result.get("mult", 1.0))
	var final_score := int(round((base_score + added_score) * pattern_mult * multiplier_mod))
	return {
		"pattern": pattern_result.get("name", ""),
		"pattern_id": pattern_result.get("id", ""),
		"base_score": base_score,
		"added_score": added_score,
		"pattern_mult": pattern_mult,
		"multiplier_mod": multiplier_mod,
		"final_score": final_score,
	}
