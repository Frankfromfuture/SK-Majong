extends Control

const BATTLE_SCENE := "res://src/scenes/battle/battle.tscn"
const MAPPER_SCENE := "res://characters/warlord1/dev/Warlord1PartsMapperScene.tscn"

@onready var preview_root: Node2D = $WarlordPreviewRoot
@onready var warlord: Node = $WarlordPreviewRoot/Warlord1
@onready var current_animation_label: Label = $ControlPanel/PanelMargin/PanelVBox/CurrentAnimationLabel
@onready var facing_label: Label = $ControlPanel/PanelMargin/PanelVBox/FacingLabel
@onready var busy_label: Label = $ControlPanel/PanelMargin/PanelVBox/BusyLabel
@onready var scale_slider: HSlider = $ControlPanel/PanelMargin/PanelVBox/ScaleSlider
@onready var speed_slider: HSlider = $ControlPanel/PanelMargin/PanelVBox/SpeedSlider
@onready var hit_log: RichTextLabel = $ControlPanel/PanelMargin/PanelVBox/HitLog


func _ready() -> void:
	_update_preview_position()
	_apply_compact_theme()
	_bind_buttons()
	scale_slider.value = float(warlord.get("pixel_scale"))
	speed_slider.value = float(warlord.get("animation_speed_scale"))
	scale_slider.value_changed.connect(_on_scale_changed)
	speed_slider.value_changed.connect(_on_speed_changed)
	warlord.animation_started.connect(_on_animation_started)
	warlord.animation_finished.connect(_on_animation_finished)
	warlord.hit_frame.connect(_on_hit_frame)
	warlord.effect_frame.connect(_on_effect_frame)
	_refresh_state()


func _process(_delta: float) -> void:
	_refresh_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_preview_position()


func _bind_buttons() -> void:
	_bind_action_button("IdleButton", "play_idle")
	_bind_action_button("ReadyButton", "play_ready")
	_bind_action_button("HorseIdleButton", "play_horse_idle")
	_bind_action_button("WalkButton", "play_walk")
	_bind_action_button("ChargeButton", "play_charge")
	_bind_action_button("AttackThrustButton", "play_attack_thrust")
	_bind_action_button("AttackSlashButton", "play_attack_slash")
	_bind_action_button("SkillAuraButton", "play_skill_command_aura")
	_bind_action_button("HitLightButton", "play_hit_light")
	_bind_action_button("HitHeavyButton", "play_hit_heavy")
	_bind_action_button("BlockButton", "play_block")
	_bind_action_button("VictoryButton", "play_victory")
	_bind_action_button("DeathButton", "play_death")
	_bind_action_button("ResetPoseButton", "reset_pose")

	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/FlipFacingButton.pressed.connect(func() -> void:
		if str(warlord.get("facing")) == "right":
			warlord.set_facing_left()
		else:
			warlord.set_facing_right()
		_refresh_state()
	)

	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/BackToBattleButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(BATTLE_SCENE)
	)
	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/OpenMapperButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(MAPPER_SCENE)
	)
	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/LoadPartsButton.pressed.connect(func() -> void:
		warlord.call("load_parts_from_map", "res://characters/warlord1/assets/parts/warlord1_parts_map.json")
		_append_log("[color=yellow]parts[/color] loaded from map")
	)
	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/UsePlaceholdersButton.pressed.connect(func() -> void:
		warlord.call("unload_real_parts")
		_append_log("[color=yellow]preview[/color] clean png")
	)
	$ControlPanel/PanelMargin/PanelVBox/ButtonsGrid/ReferenceButton.pressed.connect(func() -> void:
		warlord.call("show_reference_preview")
		_append_log("[color=yellow]preview[/color] real png")
	)


func _bind_action_button(button_name: String, action_method: String) -> void:
	var button := $ControlPanel/PanelMargin/PanelVBox/ButtonsGrid.get_node(button_name) as Button
	button.pressed.connect(func() -> void:
		if warlord.has_method(action_method):
			warlord.call(action_method)
	)


func _on_scale_changed(value: float) -> void:
	warlord.set("pixel_scale", value)
	_refresh_state()


func _on_speed_changed(value: float) -> void:
	warlord.set("animation_speed_scale", value)
	_refresh_state()


func _on_animation_started(anim_name: String) -> void:
	_append_log("[color=yellow]start[/color] %s" % anim_name)
	_refresh_state()


func _on_animation_finished(anim_name: String) -> void:
	_append_log("[color=skyblue]end[/color] %s" % anim_name)
	_refresh_state()


func _on_hit_frame(anim_name: String) -> void:
	_append_log("[color=tomato]hit[/color] %s" % anim_name)


func _on_effect_frame(anim_name: String, effect_id: String) -> void:
	_append_log("[color=orange]effect[/color] %s -> %s" % [anim_name, effect_id])


func _append_log(msg: String) -> void:
	hit_log.append_text("%s\n" % msg)
	hit_log.scroll_to_line(hit_log.get_line_count())


func _refresh_state() -> void:
	current_animation_label.text = "Anim: %s" % str(warlord.get("current_animation"))
	facing_label.text = "Facing: %s" % str(warlord.get("facing"))
	busy_label.text = "Busy: %s" % str(warlord.get("is_busy"))


func _update_preview_position() -> void:
	if preview_root == null:
		return
	var size := get_viewport_rect().size
	preview_root.position = Vector2(size.x * 0.63, size.y * 0.64)


func _apply_compact_theme() -> void:
	_apply_font_recursive(self, 8)
	for button in $ControlPanel/PanelMargin/PanelVBox/ButtonsGrid.get_children():
		if button is Button:
			button.custom_minimum_size = Vector2(82, 20)
			button.add_theme_font_size_override("font_size", 8)
	current_animation_label.add_theme_font_size_override("font_size", 8)
	facing_label.add_theme_font_size_override("font_size", 8)
	busy_label.add_theme_font_size_override("font_size", 8)
	$ControlPanel/PanelMargin/PanelVBox/ScaleLabel.add_theme_font_size_override("font_size", 8)
	$ControlPanel/PanelMargin/PanelVBox/SpeedLabel.add_theme_font_size_override("font_size", 8)
	$ControlPanel/PanelMargin/PanelVBox/HitLogLabel.add_theme_font_size_override("font_size", 8)
	hit_log.add_theme_font_size_override("normal_font_size", 7)
	scale_slider.custom_minimum_size = Vector2(0, 10)
	speed_slider.custom_minimum_size = Vector2(0, 10)


func _apply_font_recursive(node: Node, font_size: int) -> void:
	if node is Control:
		var control := node as Control
		control.add_theme_font_size_override("font_size", font_size)
	for child in node.get_children():
		_apply_font_recursive(child, font_size)
