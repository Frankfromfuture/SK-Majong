extends Node2D

signal effect_finished(effect_id: String)

@export var effect_id := ""
@export var autoplay := false
@export var one_shot := true
@export var auto_free := true
@export var playback_speed := 1.0
@export var frame_time := 0.06

var _frames: Array[Texture2D] = []
var _index := 0
var _elapsed := 0.0
var _playing := false

@onready var _sprite: Sprite2D = $EffectSprite


func _ready() -> void:
	if autoplay:
		play_effect()


func _process(delta: float) -> void:
	if not _playing or _frames.is_empty():
		return
	_elapsed += delta * maxf(0.01, playback_speed)
	if _elapsed < frame_time:
		return
	_elapsed = 0.0
	_index += 1
	if _index >= _frames.size():
		if one_shot:
			_playing = false
			emit_signal("effect_finished", effect_id)
			if auto_free:
				queue_free()
			return
		_index = 0
	_sprite.texture = _frames[_index]


func play_effect() -> void:
	if _frames.is_empty():
		_frames = _build_placeholder_frames()
	_index = 0
	_elapsed = 0.0
	_playing = true
	_sprite.texture = _frames[_index]


func play_with_textures(
	p_effect_id: String,
	textures: Array[Texture2D],
	p_speed := 1.0,
	p_one_shot := true
) -> void:
	effect_id = p_effect_id
	playback_speed = p_speed
	one_shot = p_one_shot
	_frames = textures.duplicate()
	play_effect()


func play_with_paths(
	p_effect_id: String,
	frame_paths: PackedStringArray,
	p_speed := 1.0,
	p_one_shot := true
) -> void:
	var textures: Array[Texture2D] = []
	for p in frame_paths:
		var tex := load(p) as Texture2D
		if tex != null:
			textures.append(tex)
	play_with_textures(p_effect_id, textures, p_speed, p_one_shot)


func stop_effect() -> void:
	_playing = false


func _build_placeholder_frames() -> Array[Texture2D]:
	var colors := [Color(1.0, 0.95, 0.4, 0.85), Color(1.0, 0.6, 0.25, 0.8), Color(0.8, 0.2, 0.2, 0.75)]
	var result: Array[Texture2D] = []
	for i in range(colors.size()):
		var size := 12 + i * 8
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		for y in range(size):
			for x in range(size):
				var dist := absf(float(x - size / 2)) + absf(float(y - size / 2))
				if dist <= float(size) * 0.35:
					img.set_pixel(x, y, colors[i])
		result.append(ImageTexture.create_from_image(img))
	return result
