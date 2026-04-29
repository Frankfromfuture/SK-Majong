extends Node2D
class_name Warlord1

signal animation_started(animation_name: String)
signal animation_finished(animation_name: String)
signal hit_frame(animation_name: String)
signal effect_frame(animation_name: String, effect_id: String)
signal movement_frame(animation_name: String)

const EFFECT_SCENE := preload("res://characters/warlord1/scenes/WarlordEffect2D.tscn")
const DEFAULT_MAP_PATH := "res://characters/warlord1/assets/parts/warlord1_parts_map.json"
const CUT_DIR := "res://characters/warlord1/assets/cut"
const PLACEHOLDER_DIR := "res://characters/warlord1/assets/parts/placeholders"
const CLEAN_PREVIEW_PATH := "res://characters/warlord1/assets/parts/placeholders/warlord1_preview.png"
const REFERENCE_PREVIEW_PATH := "res://characters/warlord1/assets/cut/warlord1_reference_sheet_001.png"

const RIDER_NODE_MAP := {
	"helmet_front": "RiderRoot/HeadRoot/HelmetFront",
	"golden_crown": "RiderRoot/HeadRoot/GoldenCrown",
	"helmet_back": "RiderRoot/HeadRoot/HelmetBack",
	"hidden_face_shadow": "RiderRoot/HeadRoot/HiddenFaceShadow",
	"torso_armor": "RiderRoot/Torso/TorsoSprite",
	"waist_armor": "RiderRoot/WaistArmor",
	"cape_back": "RiderRoot/CapeBack/CapeBackSprite",
	"left_shoulder_guard": "RiderRoot/LeftArmRoot/LeftShoulder",
	"left_upper_arm": "RiderRoot/LeftArmRoot/LeftUpperArm",
	"left_lower_arm": "RiderRoot/LeftArmRoot/LeftLowerArm/LeftLowerArmSprite",
	"left_hand": "RiderRoot/LeftArmRoot/LeftLowerArm/LeftHand",
	"right_shoulder_guard": "RiderRoot/RightArmRoot/RightShoulder",
	"right_upper_arm": "RiderRoot/RightArmRoot/RightUpperArm",
	"right_lower_arm": "RiderRoot/RightArmRoot/RightLowerArm/RightLowerArmSprite",
	"right_hand": "RiderRoot/RightArmRoot/RightLowerArm/RightHand",
	"left_upper_leg": "RiderRoot/LeftLegRoot/LeftUpperLeg",
	"left_lower_leg": "RiderRoot/LeftLegRoot/LeftLowerLeg/LeftLowerLegSprite",
	"left_boot": "RiderRoot/LeftLegRoot/LeftLowerLeg/LeftBoot",
	"right_upper_leg": "RiderRoot/RightLegRoot/RightUpperLeg",
	"right_lower_leg": "RiderRoot/RightLegRoot/RightLowerLeg/RightLowerLegSprite",
	"right_boot": "RiderRoot/RightLegRoot/RightLowerLeg/RightBoot",
	"saddle_connection_cloth": "RiderRoot/WaistArmor",
	"back_banner_small": "RiderRoot/BackBanner/BackBannerSprite",
	"armor_skirt_left": "RiderRoot/LeftLegRoot/LeftUpperLeg",
	"armor_skirt_right": "RiderRoot/RightLegRoot/RightUpperLeg",
}

const HORSE_NODE_MAP := {
	"horse_head": "HorseRoot/HorseNeck/HorseHead/HorseHeadSprite",
	"horse_neck": "HorseRoot/HorseNeck/HorseNeckSprite",
	"horse_body": "HorseRoot/HorseBody",
	"horse_chest_armor": "HorseRoot/HorseArmor",
	"horse_saddle": "HorseRoot/HorseSaddle",
	"horse_reins": "HorseRoot/HorseReins",
	"horse_tail": "HorseRoot/HorseTail/HorseTailSprite",
	"front_left_upper_leg": "HorseRoot/HorseFrontLeftLeg/HorseFrontLeftUpper",
	"front_left_lower_leg": "HorseRoot/HorseFrontLeftLeg/HorseFrontLeftLower/HorseFrontLeftLowerSprite",
	"front_left_hoof": "HorseRoot/HorseFrontLeftLeg/HorseFrontLeftLower/HorseFrontLeftHoof",
	"front_right_upper_leg": "HorseRoot/HorseFrontRightLeg/HorseFrontRightUpper",
	"front_right_lower_leg": "HorseRoot/HorseFrontRightLeg/HorseFrontRightLower/HorseFrontRightLowerSprite",
	"front_right_hoof": "HorseRoot/HorseFrontRightLeg/HorseFrontRightLower/HorseFrontRightHoof",
	"back_left_upper_leg": "HorseRoot/HorseBackLeftLeg/HorseBackLeftUpper",
	"back_left_lower_leg": "HorseRoot/HorseBackLeftLeg/HorseBackLeftLower/HorseBackLeftLowerSprite",
	"back_left_hoof": "HorseRoot/HorseBackLeftLeg/HorseBackLeftLower/HorseBackLeftHoof",
	"back_right_upper_leg": "HorseRoot/HorseBackRightLeg/HorseBackRightUpper",
	"back_right_lower_leg": "HorseRoot/HorseBackRightLeg/HorseBackRightLower/HorseBackRightLowerSprite",
	"back_right_hoof": "HorseRoot/HorseBackRightLeg/HorseBackRightLower/HorseBackRightHoof",
	"horse_cloth_armor": "HorseRoot/HorseArmor",
	"horse_mane": "HorseRoot/HorseNeck/HorseNeckSprite",
}

const WEAPON_NODE_MAP := {
	"long_spear_full": "WeaponRoot/Spear",
	"long_spear_tip": "WeaponRoot/Spear",
	"long_spear_shaft": "WeaponRoot/Spear",
	"long_spear_back_end": "WeaponRoot/Spear",
	"spear_motion_blur_1": "WeaponRoot/Spear",
	"spear_motion_blur_2": "WeaponRoot/Spear",
	"spear_motion_blur_3": "WeaponRoot/Spear",
	"spear_charge_glow": "WeaponRoot/Spear",
	"spear_thrust_line": "WeaponRoot/Spear",
	"spear_slash_arc": "WeaponRoot/Spear",
}

const PART_TARGET_SIZE := {
	"helmet_front": Vector2(16, 16),
	"golden_crown": Vector2(14, 10),
	"helmet_back": Vector2(16, 16),
	"hidden_face_shadow": Vector2(12, 12),
	"torso_armor": Vector2(24, 28),
	"waist_armor": Vector2(24, 14),
	"cape_back": Vector2(20, 30),
	"left_shoulder_guard": Vector2(12, 12),
	"left_upper_arm": Vector2(10, 18),
	"left_lower_arm": Vector2(10, 18),
	"left_hand": Vector2(8, 8),
	"right_shoulder_guard": Vector2(12, 12),
	"right_upper_arm": Vector2(10, 18),
	"right_lower_arm": Vector2(10, 18),
	"right_hand": Vector2(8, 8),
	"left_upper_leg": Vector2(12, 18),
	"left_lower_leg": Vector2(10, 18),
	"left_boot": Vector2(12, 8),
	"right_upper_leg": Vector2(12, 18),
	"right_lower_leg": Vector2(10, 18),
	"right_boot": Vector2(12, 8),
	"saddle_connection_cloth": Vector2(24, 14),
	"back_banner_small": Vector2(12, 24),
	"armor_skirt_left": Vector2(12, 18),
	"armor_skirt_right": Vector2(12, 18),
	"horse_head": Vector2(26, 22),
	"horse_neck": Vector2(22, 28),
	"horse_body": Vector2(58, 30),
	"horse_chest_armor": Vector2(28, 24),
	"horse_saddle": Vector2(32, 14),
	"horse_reins": Vector2(30, 12),
	"horse_tail": Vector2(28, 16),
	"front_left_upper_leg": Vector2(10, 20),
	"front_left_lower_leg": Vector2(9, 20),
	"front_left_hoof": Vector2(12, 7),
	"front_right_upper_leg": Vector2(10, 20),
	"front_right_lower_leg": Vector2(9, 20),
	"front_right_hoof": Vector2(12, 7),
	"back_left_upper_leg": Vector2(12, 21),
	"back_left_lower_leg": Vector2(10, 20),
	"back_left_hoof": Vector2(12, 7),
	"back_right_upper_leg": Vector2(12, 21),
	"back_right_lower_leg": Vector2(10, 20),
	"back_right_hoof": Vector2(12, 7),
	"horse_cloth_armor": Vector2(48, 24),
	"horse_mane": Vector2(20, 24),
	"long_spear_full": Vector2(92, 10),
	"long_spear_tip": Vector2(18, 10),
	"long_spear_shaft": Vector2(74, 6),
	"long_spear_back_end": Vector2(14, 8),
	"spear_motion_blur_1": Vector2(80, 14),
	"spear_motion_blur_2": Vector2(86, 18),
	"spear_motion_blur_3": Vector2(92, 20),
	"spear_charge_glow": Vector2(88, 18),
	"spear_thrust_line": Vector2(94, 10),
	"spear_slash_arc": Vector2(72, 36),
}

const ALL_ANIMATIONS := [
	"idle",
	"ready",
	"horse_idle",
	"walk",
	"charge",
	"attack_thrust",
	"attack_slash",
	"skill_command_aura",
	"hit_light",
	"hit_heavy",
	"block",
	"victory",
	"death",
	"reset_pose",
]

const TREE_STATES := [
	"idle",
	"ready",
	"walk",
	"charge",
	"attack_thrust",
	"attack_slash",
	"skill_command_aura",
	"hit_light",
	"hit_heavy",
	"block",
	"victory",
	"death",
]

@export var pixel_scale := 2.0:
	set(value):
		pixel_scale = maxf(0.1, value)
		_apply_scale()

@export var animation_speed_scale := 1.0:
	set(value):
		animation_speed_scale = maxf(0.05, value)
		if is_instance_valid(animation_player):
			animation_player.speed_scale = animation_speed_scale

@export var parts_map_path := DEFAULT_MAP_PATH
@export var use_real_parts := false
@export var use_clean_preview := true

var current_state := "idle"
var is_busy := false
var facing := "right"
var current_animation := "idle"
var hp_ratio := 1.0

var _effect_frames := {}
var _sprite_placeholders := {}
var _default_pose := {}
var _hit_trigger_guard := {}
var _movement_trigger_guard := {}
var _library: AnimationLibrary
var _tree_playback
var _tree_state_nodes := {}
var _reference_preview: Sprite2D

@onready var shadow: Sprite2D = $Shadow
@onready var horse_root: Node2D = $HorseRoot
@onready var rider_root: Node2D = $RiderRoot
@onready var weapon_root: Node2D = $WeaponRoot
@onready var effects_root: Node2D = $EffectsRoot
@onready var hit_anchor: Node2D = $HitAnchor
@onready var weapon_tip_anchor: Node2D = $WeaponTipAnchor
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree


func _ready() -> void:
	_cache_default_pose()
	_assign_placeholder_textures(true)
	_setup_shadow_placeholder()
	_setup_animation_system()
	if use_real_parts:
		load_parts_from_map(parts_map_path)
	elif use_clean_preview:
		show_clean_preview()
	reset_pose()
	play_idle()


func _process(_delta: float) -> void:
	if current_animation == "attack_thrust" and not _hit_trigger_guard.get("attack_thrust", false):
		if animation_player.current_animation_position >= 0.34:
			_hit_trigger_guard["attack_thrust"] = true
			_emit_hit_and_effect("attack_thrust", "spear_thrust_flash")
	if current_animation == "attack_slash" and not _hit_trigger_guard.get("attack_slash", false):
		if animation_player.current_animation_position >= 0.36:
			_hit_trigger_guard["attack_slash"] = true
			_emit_hit_and_effect("attack_slash", "spear_slash_arc")
	if current_animation == "charge" and not _movement_trigger_guard.get("charge", false):
		if animation_player.current_animation_position >= 0.24:
			_movement_trigger_guard["charge"] = true
			emit_signal("movement_frame", "charge")
			spawn_effect("horse_charge_dust", Vector2(-8, 46))
	if current_animation == "skill_command_aura" and not _effect_frames_fired("skill_command_aura"):
		if animation_player.current_animation_position >= 0.28:
			_movement_trigger_guard["skill_command_aura"] = true
			spawn_effect("red_command_aura", rider_root.position + Vector2(0, -12))
			spawn_effect("black_wind_trail", rider_root.position + Vector2(-12, -8))
			emit_signal("effect_frame", "skill_command_aura", "red_command_aura")
			emit_signal("effect_frame", "skill_command_aura", "black_wind_trail")
	if current_animation == "hit_heavy" and not _movement_trigger_guard.get("hit_heavy", false):
		if animation_player.current_animation_position >= 0.18:
			_movement_trigger_guard["hit_heavy"] = true
			spawn_effect("impact_spark", hit_anchor.position)
			emit_signal("effect_frame", "hit_heavy", "impact_spark")
	if current_animation == "walk" and animation_player.current_animation_length > 0.0:
		var phase := int(floor(animation_player.current_animation_position / animation_player.current_animation_length * 4.0))
		var walk_phase := int(_movement_trigger_guard.get("walk_phase", -1))
		if phase != walk_phase and (phase == 1 or phase == 3):
			_movement_trigger_guard["walk_phase"] = phase
			emit_signal("movement_frame", "walk")


func load_parts_from_map(map_path: String) -> void:
	use_real_parts = true
	use_clean_preview = false
	_set_reference_preview_visible(false)
	_set_body_visible(true)
	var use_path := map_path if not map_path.is_empty() else DEFAULT_MAP_PATH
	if not FileAccess.file_exists(use_path):
		return
	var file := FileAccess.open(use_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	_auto_fill_missing_with_keywords(data)
	_apply_map_section(data.get("rider", {}), RIDER_NODE_MAP)
	_apply_map_section(data.get("horse", {}), HORSE_NODE_MAP)
	_apply_map_section(data.get("weapon", {}), WEAPON_NODE_MAP)
	_load_effect_frames(data.get("effects", {}))


func unload_real_parts() -> void:
	use_real_parts = false
	use_clean_preview = true
	_assign_placeholder_textures(true)
	show_clean_preview()


func show_clean_preview() -> void:
	use_real_parts = false
	use_clean_preview = true
	_show_preview_texture(CLEAN_PREVIEW_PATH, Vector2(150, 100), Vector2(0, -8))


func show_reference_preview() -> void:
	show_clean_preview()


func hide_reference_preview() -> void:
	_set_reference_preview_visible(false)


func set_facing_right() -> void:
	facing = "right"
	_apply_scale()


func set_facing_left() -> void:
	facing = "left"
	_apply_scale()


func play_idle() -> void:
	_play_action("idle", false, "idle")


func play_ready() -> void:
	_play_action("ready", false, "ready")


func play_horse_idle() -> void:
	_play_action("horse_idle", false, "horse_idle")


func play_walk() -> void:
	_play_action("walk", false, "walk")


func play_charge() -> void:
	_play_action("charge", true, "charge")


func play_attack_thrust() -> void:
	_play_action("attack_thrust", true, "attack_thrust")


func play_attack_slash() -> void:
	_play_action("attack_slash", true, "attack_slash")


func play_skill_command_aura() -> void:
	_play_action("skill_command_aura", true, "skill_command_aura")


func play_hit_light() -> void:
	_play_action("hit_light", true, "hit_light")


func play_hit_heavy() -> void:
	_play_action("hit_heavy", true, "hit_heavy")


func play_block() -> void:
	_play_action("block", true, "block")


func play_victory() -> void:
	_play_action("victory", false, "victory")


func play_death() -> void:
	_play_action("death", true, "death")


func stop_all_effects() -> void:
	for child in effects_root.get_children():
		if child.has_method("stop_effect"):
			child.call("stop_effect")
		child.queue_free()


func spawn_effect(effect_id: String, position: Vector2) -> void:
	if EFFECT_SCENE == null:
		return
	var inst := EFFECT_SCENE.instantiate()
	if inst == null:
		return
	effects_root.add_child(inst)
	inst.position = position
	var textures: Array[Texture2D] = []
	var frame_paths = _effect_frames.get(effect_id, [])
	for p in frame_paths:
		var tex := load(str(p)) as Texture2D
		if tex != null:
			textures.append(tex)
	inst.call("play_with_textures", effect_id, textures, animation_speed_scale, true)


func reset_pose() -> void:
	for node_path in _default_pose.keys():
		var payload: Dictionary = _default_pose[node_path]
		var node := get_node_or_null(node_path)
		if node == null:
			continue
		node.position = payload.get("position", Vector2.ZERO)
		node.rotation = payload.get("rotation", 0.0)
		node.scale = payload.get("scale", Vector2.ONE)
	self.modulate = Color(1, 1, 1, 1)
	stop_all_effects()
	_play_action("reset_pose", false, "idle")


func _setup_animation_system() -> void:
	if animation_player.has_animation_library(""):
		_library = animation_player.get_animation_library("")
	else:
		_library = AnimationLibrary.new()
		animation_player.add_animation_library("", _library)
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.speed_scale = animation_speed_scale
	_ensure_animations()
	_setup_animation_tree()
	animation_tree.active = true


func _setup_animation_tree() -> void:
	var sm := AnimationNodeStateMachine.new()
	_tree_state_nodes.clear()
	for i in range(TREE_STATES.size()):
		var state_name := String(TREE_STATES[i])
		var anim_node := AnimationNodeAnimation.new()
		anim_node.animation = state_name
		sm.add_node(state_name, anim_node, Vector2(float(i % 4) * 220.0, float(i / 4) * 120.0))
		_tree_state_nodes[state_name] = true
	if sm.has_method("set_start_node"):
		sm.call("set_start_node", "idle")
	_add_state_transition(sm, "idle", "ready", 0.08)
	_add_state_transition(sm, "idle", "walk", 0.08)
	_add_state_transition(sm, "idle", "charge", 0.08)
	_add_state_transition(sm, "idle", "attack_thrust", 0.05)
	_add_state_transition(sm, "idle", "attack_slash", 0.05)
	_add_state_transition(sm, "idle", "skill_command_aura", 0.08)
	_add_state_transition(sm, "idle", "hit_light", 0.02)
	_add_state_transition(sm, "idle", "hit_heavy", 0.02)
	_add_state_transition(sm, "idle", "block", 0.04)
	_add_state_transition(sm, "idle", "victory", 0.10)
	_add_state_transition(sm, "ready", "idle", 0.08)
	_add_state_transition(sm, "ready", "walk", 0.08)
	_add_state_transition(sm, "ready", "charge", 0.06)
	_add_state_transition(sm, "ready", "attack_thrust", 0.04)
	_add_state_transition(sm, "ready", "attack_slash", 0.04)
	_add_state_transition(sm, "ready", "skill_command_aura", 0.08)
	_add_state_transition(sm, "ready", "hit_light", 0.02)
	_add_state_transition(sm, "ready", "hit_heavy", 0.02)
	_add_state_transition(sm, "ready", "block", 0.04)
	_add_state_transition(sm, "walk", "ready", 0.06)
	_add_state_transition(sm, "walk", "charge", 0.05)
	_add_state_transition(sm, "walk", "attack_thrust", 0.04)
	_add_state_transition(sm, "charge", "attack_thrust", 0.02)
	_add_state_transition(sm, "charge", "ready", 0.04)
	_add_state_transition(sm, "attack_thrust", "ready", 0.02)
	_add_state_transition(sm, "attack_slash", "ready", 0.03)
	_add_state_transition(sm, "skill_command_aura", "ready", 0.04)
	_add_state_transition(sm, "hit_light", "idle", 0.03)
	_add_state_transition(sm, "hit_heavy", "idle", 0.04)
	_add_state_transition(sm, "block", "ready", 0.03)
	_add_state_transition(sm, "victory", "idle", 0.12)
	for s in TREE_STATES:
		if s == "death":
			continue
		_add_state_transition(sm, s, "death", 0.02)
	animation_tree.tree_root = sm
	_tree_playback = animation_tree.get("parameters/playback")
	if _tree_playback != null and _tree_playback.has_method("travel"):
		_tree_playback.call("travel", "idle")


func _add_state_transition(sm: AnimationNodeStateMachine, from_state: String, to_state: String, xfade: float) -> void:
	if not _tree_state_nodes.has(from_state) or not _tree_state_nodes.has(to_state):
		return
	var transition := AnimationNodeStateMachineTransition.new()
	transition.xfade_time = xfade
	transition.reset = true
	sm.add_transition(from_state, to_state, transition)


func _ensure_animations() -> void:
	_upsert_animation(_make_idle_animation())
	_upsert_animation(_make_ready_animation())
	_upsert_animation(_make_horse_idle_animation())
	_upsert_animation(_make_walk_animation())
	_upsert_animation(_make_charge_animation())
	_upsert_animation(_make_attack_thrust_animation())
	_upsert_animation(_make_attack_slash_animation())
	_upsert_animation(_make_skill_aura_animation())
	_upsert_animation(_make_hit_light_animation())
	_upsert_animation(_make_hit_heavy_animation())
	_upsert_animation(_make_block_animation())
	_upsert_animation(_make_victory_animation())
	_upsert_animation(_make_death_animation())
	_upsert_animation(_make_reset_pose_animation())


func _upsert_animation(anim: Animation) -> void:
	var name := anim.resource_name
	if _library.has_animation(name):
		_library.remove_animation(name)
	_library.add_animation(name, anim)


func _make_idle_animation() -> Animation:
	var anim := _anim("idle", 1.2, true)
	_track(anim, "RiderRoot:position", [{t = 0.0, v = Vector2(0, -2)}, {t = 0.3, v = Vector2(0, -3)}, {t = 0.6, v = Vector2(0, -4)}, {t = 0.9, v = Vector2(0, -3)}, {t = 1.2, v = Vector2(0, -2)}])
	_track(anim, "HorseRoot:position", [{t = 0.0, v = Vector2(0, 18)}, {t = 0.3, v = Vector2(0, 19)}, {t = 0.6, v = Vector2(0, 20)}, {t = 0.9, v = Vector2(0, 19)}, {t = 1.2, v = Vector2(0, 18)}])
	_track(anim, "RiderRoot/CapeBack:rotation_degrees", [{t = 0.0, v = -3.0}, {t = 0.6, v = 4.0}, {t = 1.2, v = -3.0}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = 4.0}, {t = 0.6, v = 6.5}, {t = 1.2, v = 4.0}])
	return anim


func _make_ready_animation() -> Animation:
	var anim := _anim("ready", 0.8, true)
	_track(anim, "RiderRoot:position", [{t = 0.0, v = Vector2(0, -2)}, {t = 0.4, v = Vector2(3, -1)}, {t = 0.8, v = Vector2(0, -2)}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = 4.0}, {t = 0.2, v = -1.0}, {t = 0.4, v = -5.0}, {t = 0.8, v = 4.0}])
	_track(anim, "HorseRoot/HorseNeck/HorseHead:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.4, v = 4.0}, {t = 0.8, v = 0.0}])
	return anim


func _make_horse_idle_animation() -> Animation:
	var anim := _anim("horse_idle", 1.0, true)
	_track(anim, "HorseRoot/HorseNeck/HorseHead:rotation_degrees", [{t = 0.0, v = -2.0}, {t = 0.5, v = 3.0}, {t = 1.0, v = -2.0}])
	_track(anim, "HorseRoot/HorseTail:rotation_degrees", [{t = 0.0, v = 5.0}, {t = 0.5, v = -7.0}, {t = 1.0, v = 5.0}])
	_track(anim, "HorseRoot/HorseFrontLeftLeg:position:y", [{t = 0.0, v = 16.0}, {t = 0.5, v = 15.0}, {t = 1.0, v = 16.0}])
	_track(anim, "HorseRoot/HorseBackRightLeg:position:y", [{t = 0.0, v = 15.0}, {t = 0.5, v = 16.0}, {t = 1.0, v = 15.0}])
	return anim


func _make_walk_animation() -> Animation:
	var anim := _anim("walk", 0.8, true)
	_track(anim, "HorseRoot/HorseFrontLeftLeg:rotation_degrees", [{t = 0.0, v = -10.0}, {t = 0.2, v = -2.0}, {t = 0.4, v = 10.0}, {t = 0.6, v = -2.0}, {t = 0.8, v = -10.0}])
	_track(anim, "HorseRoot/HorseFrontRightLeg:rotation_degrees", [{t = 0.0, v = 10.0}, {t = 0.2, v = 2.0}, {t = 0.4, v = -10.0}, {t = 0.6, v = 2.0}, {t = 0.8, v = 10.0}])
	_track(anim, "HorseRoot/HorseBackLeftLeg:rotation_degrees", [{t = 0.0, v = 9.0}, {t = 0.2, v = 2.0}, {t = 0.4, v = -9.0}, {t = 0.6, v = 2.0}, {t = 0.8, v = 9.0}])
	_track(anim, "HorseRoot/HorseBackRightLeg:rotation_degrees", [{t = 0.0, v = -9.0}, {t = 0.2, v = -2.0}, {t = 0.4, v = 9.0}, {t = 0.6, v = -2.0}, {t = 0.8, v = -9.0}])
	_track(anim, "RiderRoot:position:y", [{t = 0.0, v = -2.0}, {t = 0.4, v = -4.0}, {t = 0.8, v = -2.0}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = 6.0}, {t = 0.4, v = 3.0}, {t = 0.8, v = 6.0}])
	return anim


func _make_charge_animation() -> Animation:
	var anim := _anim("charge", 0.56, false)
	_track(anim, "HorseRoot:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.28, v = -3.0}, {t = 0.56, v = -6.0}])
	_track(anim, "RiderRoot:position", [{t = 0.0, v = Vector2(0, -2)}, {t = 0.18, v = Vector2(2, -1)}, {t = 0.56, v = Vector2(6, 3)}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = 4.0}, {t = 0.16, v = -8.0}, {t = 0.56, v = -15.0}])
	_track(anim, "HorseRoot/HorseFrontLeftLeg:rotation_degrees", [{t = 0.0, v = -12.0}, {t = 0.3, v = 14.0}, {t = 0.6, v = -12.0}])
	_track(anim, "HorseRoot/HorseFrontRightLeg:rotation_degrees", [{t = 0.0, v = 14.0}, {t = 0.3, v = -12.0}, {t = 0.6, v = 14.0}])
	return anim


func _make_attack_thrust_animation() -> Animation:
	var anim := _anim("attack_thrust", 0.66, false)
	_track(anim, "WeaponRoot/Spear:position", [{t = 0.0, v = Vector2(30, 0)}, {t = 0.18, v = Vector2(16, -4)}, {t = 0.32, v = Vector2(52, -4)}, {t = 0.66, v = Vector2(30, 0)}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = -10.0}, {t = 0.18, v = -24.0}, {t = 0.32, v = -4.0}, {t = 0.66, v = -10.0}])
	_track(anim, "RiderRoot:position", [{t = 0.0, v = Vector2(0, -2)}, {t = 0.18, v = Vector2(-3, -1)}, {t = 0.32, v = Vector2(8, -5)}, {t = 0.66, v = Vector2(0, -2)}])
	return anim


func _make_attack_slash_animation() -> Animation:
	var anim := _anim("attack_slash", 0.72, false)
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = -4.0}, {t = 0.2, v = -56.0}, {t = 0.34, v = 24.0}, {t = 0.72, v = -4.0}])
	_track(anim, "WeaponRoot/Spear:position", [{t = 0.0, v = Vector2(30, 0)}, {t = 0.2, v = Vector2(24, -12)}, {t = 0.34, v = Vector2(40, 4)}, {t = 0.72, v = Vector2(30, 0)}])
	_track(anim, "RiderRoot/Torso:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.2, v = -8.0}, {t = 0.34, v = 5.0}, {t = 0.72, v = 0.0}])
	return anim


func _make_skill_aura_animation() -> Animation:
	var anim := _anim("skill_command_aura", 1.0, false)
	_track(anim, "RiderRoot:position", [{t = 0.0, v = Vector2(0, -2)}, {t = 0.25, v = Vector2(0, -8)}, {t = 0.7, v = Vector2(0, -5)}, {t = 1.0, v = Vector2(0, -2)}])
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = 2.0}, {t = 0.25, v = -84.0}, {t = 0.7, v = -90.0}, {t = 1.0, v = 2.0}])
	_track(anim, "HorseRoot/HorseFrontLeftLeg:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.3, v = -18.0}, {t = 0.6, v = -2.0}, {t = 1.0, v = 0.0}])
	return anim


func _make_hit_light_animation() -> Animation:
	var anim := _anim("hit_light", 0.38, false)
	_track(anim, ".:modulate", [{t = 0.0, v = Color(1, 1, 1, 1)}, {t = 0.08, v = Color(1.6, 1.6, 1.6, 1)}, {t = 0.2, v = Color(1, 1, 1, 1)}])
	_track(anim, ".:position:x", [{t = 0.0, v = 0.0}, {t = 0.08, v = -5.0}, {t = 0.22, v = -1.0}, {t = 0.38, v = 0.0}])
	return anim


func _make_hit_heavy_animation() -> Animation:
	var anim := _anim("hit_heavy", 0.62, false)
	_track(anim, ".:position:x", [{t = 0.0, v = 0.0}, {t = 0.15, v = -14.0}, {t = 0.46, v = -8.0}, {t = 0.62, v = 0.0}])
	_track(anim, "HorseRoot/HorseNeck/HorseHead:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.2, v = -15.0}, {t = 0.62, v = 0.0}])
	_track(anim, "RiderRoot:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.2, v = -8.0}, {t = 0.62, v = 0.0}])
	return anim


func _make_block_animation() -> Animation:
	var anim := _anim("block", 0.42, false)
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = -4.0}, {t = 0.14, v = -38.0}, {t = 0.42, v = -18.0}])
	_track(anim, "RiderRoot:scale", [{t = 0.0, v = Vector2(1, 1)}, {t = 0.14, v = Vector2(0.97, 0.96)}, {t = 0.42, v = Vector2(1, 1)}])
	return anim


func _make_victory_animation() -> Animation:
	var anim := _anim("victory", 1.0, true)
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = -8.0}, {t = 0.5, v = -92.0}, {t = 1.0, v = -84.0}])
	_track(anim, "HorseRoot/HorseNeck/HorseHead:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.5, v = -8.0}, {t = 1.0, v = -2.0}])
	_track(anim, "RiderRoot/CapeBack:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.5, v = -12.0}, {t = 1.0, v = -4.0}])
	return anim


func _make_death_animation() -> Animation:
	var anim := _anim("death", 1.0, false)
	_track(anim, "WeaponRoot/Spear:rotation_degrees", [{t = 0.0, v = -8.0}, {t = 0.5, v = 40.0}, {t = 1.0, v = 70.0}])
	_track(anim, "RiderRoot:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 0.5, v = 16.0}, {t = 1.0, v = 24.0}])
	_track(anim, "HorseRoot/HorseNeck/HorseHead:rotation_degrees", [{t = 0.0, v = 0.0}, {t = 1.0, v = 10.0}])
	_track(anim, ".:modulate:a", [{t = 0.0, v = 1.0}, {t = 1.0, v = 0.42}])
	return anim


func _make_reset_pose_animation() -> Animation:
	var anim := _anim("reset_pose", 0.1, false)
	_track(anim, ".:position", [{t = 0.0, v = Vector2.ZERO}])
	_track(anim, ".:modulate", [{t = 0.0, v = Color(1, 1, 1, 1)}])
	return anim


func _anim(name: String, length: float, loop: bool) -> Animation:
	var anim := Animation.new()
	anim.resource_name = name
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	return anim


func _track(anim: Animation, path: String, keys: Array) -> void:
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath(path))
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)
	for key in keys:
		anim.track_insert_key(track_idx, key["t"], key["v"])


func _play_action(anim_name: String, busy: bool, next_state: String) -> void:
	if not _library.has_animation(anim_name):
		return
	if current_state == "death" and anim_name != "death" and anim_name != "reset_pose":
		return
	is_busy = busy
	current_state = next_state
	current_animation = anim_name
	_hit_trigger_guard.erase(anim_name)
	_movement_trigger_guard.erase(anim_name)
	if _tree_state_nodes.has(anim_name) and _tree_playback != null and _tree_playback.has_method("travel"):
		_tree_playback.call("travel", anim_name)
	else:
		animation_player.play(anim_name)
	emit_signal("animation_started", anim_name)


func _on_animation_finished(anim_name: StringName) -> void:
	var name := String(anim_name)
	emit_signal("animation_finished", name)
	match name:
		"attack_thrust", "attack_slash":
			is_busy = false
			play_ready()
		"charge":
			is_busy = false
			if current_state == "charge":
				play_ready()
		"hit_light", "hit_heavy":
			is_busy = false
			play_idle()
		"block":
			is_busy = false
			play_ready()
		"skill_command_aura":
			is_busy = false
			play_ready()
		"death":
			is_busy = true
			current_state = "death"
		"reset_pose":
			is_busy = false
			current_state = "idle"
		_:
			if not animation_player.is_playing():
				is_busy = false


func _emit_hit_and_effect(anim_name: String, effect_id: String) -> void:
	emit_signal("hit_frame", anim_name)
	emit_signal("effect_frame", anim_name, effect_id)
	spawn_effect(effect_id, weapon_tip_anchor.position)


func _effect_frames_fired(key: String) -> bool:
	return _movement_trigger_guard.get(key, false)


func _apply_map_section(section: Dictionary, node_map: Dictionary) -> void:
	_set_reference_preview_visible(false)
	for part_name in section.keys():
		if not node_map.has(part_name):
			continue
		var node_path := String(node_map[part_name])
		var sprite := get_node_or_null(node_path) as Sprite2D
		if sprite == null:
			continue
		var texture := _load_part_texture(section.get(part_name, ""))
		if texture != null:
			sprite.texture = texture
			_fit_sprite_to_part(sprite, String(part_name))


func _load_part_texture(raw_path: Variant) -> Texture2D:
	var p := str(raw_path).strip_edges()
	if p.is_empty():
		return null
	if not p.begins_with("res://"):
		p = "%s/%s" % [CUT_DIR, p]
	var tex := load(p) as Texture2D
	return tex


func _show_preview_texture(preview_path: String, target_size: Vector2, preview_position: Vector2) -> void:
	if not ResourceLoader.exists(preview_path):
		return
	var tex := load(preview_path) as Texture2D
	if tex == null:
		return
	if _reference_preview == null or not is_instance_valid(_reference_preview):
		_reference_preview = Sprite2D.new()
		_reference_preview.name = "PreviewPng"
		_reference_preview.centered = true
		add_child(_reference_preview)
		move_child(_reference_preview, 1)
	_reference_preview.texture = tex
	var tex_size := tex.get_size()
	var fit := minf(target_size.x / tex_size.x, target_size.y / tex_size.y)
	_reference_preview.scale = Vector2.ONE * fit
	_reference_preview.position = preview_position
	_set_body_visible(false)
	_reference_preview.visible = true


func _set_reference_preview_visible(visible: bool) -> void:
	if visible:
		show_clean_preview()
		return
	if _reference_preview != null and is_instance_valid(_reference_preview):
		_reference_preview.visible = visible
	_set_body_visible(not visible)


func _set_body_visible(visible: bool) -> void:
	shadow.visible = visible
	horse_root.visible = visible
	rider_root.visible = visible
	weapon_root.visible = visible


func _fit_sprite_to_part(sprite: Sprite2D, part_name: String) -> void:
	if sprite.texture == null:
		return
	var target: Vector2 = PART_TARGET_SIZE.get(part_name, Vector2(16, 16))
	var tex_size := sprite.texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale_factor: float = minf(target.x / tex_size.x, target.y / tex_size.y)
	sprite.scale = Vector2.ONE * scale_factor
	sprite.centered = true


func _load_effect_frames(effects_section: Dictionary) -> void:
	_effect_frames.clear()
	for effect_id in effects_section.keys():
		var frames := []
		for v in effects_section.get(effect_id, []):
			var p := str(v).strip_edges()
			if p.is_empty():
				continue
			if not p.begins_with("res://"):
				p = "%s/%s" % [CUT_DIR, p]
			frames.append(p)
		_effect_frames[effect_id] = frames


func _auto_fill_missing_with_keywords(map_data: Dictionary) -> void:
	var dir := DirAccess.open(CUT_DIR)
	if dir == null:
		return
	var cut_files := PackedStringArray()
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f.is_empty():
			break
		if dir.current_is_dir():
			continue
		if f.get_extension().to_lower() == "png":
			cut_files.append(f)
	dir.list_dir_end()
	cut_files.sort()
	_auto_fill_section(map_data.get("rider", {}), cut_files)
	_auto_fill_section(map_data.get("horse", {}), cut_files)
	_auto_fill_section(map_data.get("weapon", {}), cut_files)


func _auto_fill_section(section: Dictionary, cut_files: PackedStringArray) -> void:
	for key in section.keys():
		var existing := str(section[key]).strip_edges()
		if not existing.is_empty():
			continue
		var keyword := String(key).to_lower()
		for file_name in cut_files:
			if file_name.to_lower().find(keyword) >= 0:
				section[key] = file_name
				break


func _cache_default_pose() -> void:
	var capture_nodes := [
		".",
		"HorseRoot",
		"RiderRoot",
		"WeaponRoot",
		"RiderRoot/Torso",
		"RiderRoot/CapeBack",
		"HorseRoot/HorseNeck/HorseHead",
		"HorseRoot/HorseTail",
		"HorseRoot/HorseFrontLeftLeg",
		"HorseRoot/HorseFrontRightLeg",
		"HorseRoot/HorseBackLeftLeg",
		"HorseRoot/HorseBackRightLeg",
	]
	for p in capture_nodes:
		var n := get_node_or_null(p) as Node2D
		if n == null:
			continue
		_default_pose[p] = {
			"position": n.position,
			"rotation": n.rotation,
			"scale": n.scale,
		}


func _assign_placeholder_textures(force := false) -> void:
	for node in _all_sprite_nodes(self):
		if force or node.texture == null:
			node.texture = _placeholder_for(node.name)
			node.centered = true
			node.scale = Vector2.ONE


func _setup_shadow_placeholder() -> void:
	if shadow.texture != null:
		return
	var w := 56
	var h := 16
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in range(h):
		for x in range(w):
			var nx := (float(x) - w * 0.5) / (w * 0.5)
			var ny := (float(y) - h * 0.5) / (h * 0.5)
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.75))
	shadow.texture = ImageTexture.create_from_image(img)
	shadow.centered = true


func _all_sprite_nodes(root: Node) -> Array:
	var result: Array = []
	for child in root.get_children():
		if child is Sprite2D:
			result.append(child)
		if child.get_child_count() > 0:
			result.append_array(_all_sprite_nodes(child))
	return result


func _placeholder_for(name: String) -> Texture2D:
	if _sprite_placeholders.has(name):
		return _sprite_placeholders[name]
	var placeholder_path := "%s/%s.png" % [PLACEHOLDER_DIR, name]
	if ResourceLoader.exists(placeholder_path):
		var loaded := load(placeholder_path) as Texture2D
		if loaded != null:
			_sprite_placeholders[name] = loaded
			return loaded
	var size := Vector2i(16, 16)
	var color := Color(0.6, 0.6, 0.65, 0.9)
	var key := name.to_lower()
	if key.find("horse") >= 0:
		size = Vector2i(26, 14)
		color = Color(0.20, 0.22, 0.26, 0.95)
	elif key.find("spear") >= 0:
		size = Vector2i(48, 4)
		color = Color(0.72, 0.58, 0.25, 0.95)
	elif key.find("cape") >= 0 or key.find("banner") >= 0:
		size = Vector2i(12, 18)
		color = Color(0.58, 0.12, 0.12, 0.9)
	elif key.find("head") >= 0 or key.find("helmet") >= 0 or key.find("crown") >= 0:
		size = Vector2i(12, 12)
		color = Color(0.82, 0.66, 0.24, 0.95)
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	for y in range(size.y):
		for x in range(size.x):
			if x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1:
				img.set_pixel(x, y, Color(0.08, 0.08, 0.08, 0.95))
	var tex := ImageTexture.create_from_image(img)
	_sprite_placeholders[name] = tex
	return tex


func _apply_scale() -> void:
	var direction := -1.0 if facing == "left" else 1.0
	scale = Vector2(pixel_scale * direction, pixel_scale)
