extends SceneTree

const PatternMatcherScript = preload("res://src/core/pattern_matcher.gd")


func _init() -> void:
	var output := [
		"# Pattern Table",
		"",
		"| 等级 | 牌型 | ID | 张数 | 基础分 | 倍率 |",
		"|---:|---|---|---:|---:|---:|",
	]

	var patterns := PatternMatcherScript.PATTERNS.duplicate()
	patterns.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("level", 0)) < int(b.get("level", 0)))
	for pattern in patterns:
		output.append("| %s | %s | `%s` | %s | %s | x%s |" % [
			pattern.get("level", 0),
			pattern.get("name", ""),
			pattern.get("id", ""),
			pattern.get("tile_count", 0),
			pattern.get("base_score", 0),
			_format_mult(pattern.get("mult", 1.0)),
		])

	output.append("")
	output.append("## MVP 判定备注")
	output.append("")
	output.append("- 核心识别器暂时支持 1-9 张选择，以覆盖一气通贯的 9 张测试。")
	output.append("- 役满在策划表中写作 7 张，但「雀头 + 面子 + 面子」数学上是 8 张。Phase 1 暂定为：雀头 + 1 个三张面子 + 1 个两张搭子或对子。后续进入玩法调优时需要确认最终定义。")

	var file := FileAccess.open("res://docs/pattern_table.md", FileAccess.WRITE)
	file.store_string("\n".join(output) + "\n")
	file.close()
	quit()


func _format_mult(value: Variant) -> String:
	var float_value := float(value)
	if is_equal_approx(float_value, roundf(float_value)):
		return str(int(float_value))
	return str(float_value)
