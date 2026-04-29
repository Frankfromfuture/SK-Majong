class_name LayeredBackground
extends Control

@export var variant := "battle"
@export var show_shader_base := true
@export var show_banners := true
@export var show_symbols := true

var _time := 0.0
var _floaters: Array[Control] = []
var _sparkles: Array[ColorRect] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()


func _process(delta: float) -> void:
	_time += delta
	for i in range(_floaters.size()):
		var floater := _floaters[i]
		floater.position.y += sin(_time * (0.9 + i * 0.07) + i) * 0.08
		floater.rotation_degrees = sin(_time * 0.7 + i * 0.4) * 2.5
	for i in range(_sparkles.size()):
		var spark := _sparkles[i]
		spark.position.x += 10.0 * delta
		spark.position.y += sin(_time * 2.2 + i) * 0.18
		spark.modulate.a = 0.35 + max(sin(_time * 4.0 + i * 1.8), 0.0) * 0.55
		if spark.position.x > 650.0:
			spark.position.x = -12.0


func _build() -> void:
	if show_shader_base:
		var base := ColorRect.new()
		base.name = "AnimatedShaderBase"
		base.set_anchors_preset(Control.PRESET_FULL_RECT)
		base.material = _make_background_material()
		add_child(base)

	var banner_layer := Control.new()
	banner_layer.name = "LoopingBannerLayer"
	banner_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(banner_layer)

	if show_banners:
		for i in range(6):
			var banner := ColorRect.new()
			banner.name = "BannerRibbon_%02d" % i
			banner.color = Color(0.42, 0.035, 0.04, 0.5)
			banner.position = Vector2(46 + i * 96, 16 + (i % 2) * 28)
			banner.size = Vector2(64, 14)
			banner.rotation_degrees = -12 + i * 4
			banner_layer.add_child(banner)
			_floaters.append(banner)

	var symbol_layer := Control.new()
	symbol_layer.name = "FloatingMahjongSymbolLayer"
	symbol_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(symbol_layer)

	if show_symbols:
		var symbols := ["万", "饼", "条", "東", "南", "白", "中"]
		for i in range(symbols.size()):
			var label := Label.new()
			label.name = "FloatingSymbol_%02d" % i
			label.text = symbols[i]
			label.position = Vector2(42 + i * 84, 70 + sin(i) * 46)
			label.add_theme_font_size_override("font_size", 22 + (i % 3) * 4)
			label.add_theme_color_override("font_color", Color(0.95, 0.32, 0.2, 0.25) if i % 2 == 0 else Color(0.2, 0.85, 0.58, 0.22))
			symbol_layer.add_child(label)
			_floaters.append(label)

	var sparkle_layer := Control.new()
	sparkle_layer.name = "LoopingSparkLayer"
	sparkle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sparkle_layer)
	for i in range(24):
		var spark := ColorRect.new()
		spark.name = "Spark_%02d" % i
		spark.position = Vector2((i * 29) % 640, 34 + ((i * 47) % 280))
		spark.size = Vector2(2 + i % 2, 2 + i % 3)
		spark.color = Color(1.0, 0.46, 0.12, 0.72) if i % 3 else Color(0.18, 1.0, 0.58, 0.5)
		sparkle_layer.add_child(spark)
		_sparkles.append(spark)

	var scanlines := ColorRect.new()
	scanlines.name = "CrtScanlineOverlay"
	scanlines.set_anchors_preset(Control.PRESET_FULL_RECT)
	scanlines.material = _make_scanline_material()
	add_child(scanlines)


func _make_background_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	float table = sin(uv.x * 34.0 + sin(uv.y * 10.0) * 3.0 + TIME * 0.25) * 0.028;
	float pulse = sin(TIME * 1.9 + uv.x * 7.0 + uv.y * 3.0) * 0.5 + 0.5;
	float radial = 1.0 - smoothstep(0.08, 0.75, distance(uv, vec2(0.55, 0.46)));
	vec3 base = mix(vec3(0.030, 0.010, 0.014), vec3(0.18, 0.040, 0.035), uv.y);
	vec3 jade = vec3(0.0, 0.42, 0.25) * radial * 0.36;
	vec3 bronze = vec3(0.95, 0.38, 0.08) * pulse * 0.12;
	float vignette = smoothstep(0.35, 0.82, distance(uv, vec2(0.5)));
	COLOR = vec4(base + table + jade + bronze - vignette * 0.18, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _make_scanline_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float scan = max(sin((UV.y + TIME * 0.17) * 800.0), 0.0);
	float chroma = max(sin((UV.x + TIME * 0.05) * 70.0), 0.0);
	float vignette = smoothstep(0.42, 0.86, distance(UV, vec2(0.5)));
	COLOR = vec4(0.0, 0.0, 0.0, scan * 0.075 + chroma * 0.018 + vignette * 0.26);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material
