extends Control

const AnimatedButtonScript = preload("res://src/ui/animated_button.gd")
const LayeredBackgroundScript = preload("res://src/ui/layered_background.gd")

var _time := 0.0
var main_title: Label
var subtitle_label: Label
var decorative_tiles: Array[Label] = []


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	_build_menu()


func _process(delta: float) -> void:
	_time += delta
	if main_title != null:
		main_title.position.x = 50.0 + sin(_time * 1.45) * 3.0
		main_title.scale = Vector2.ONE * (1.0 + sin(_time * 2.0) * 0.012)
	if subtitle_label != null:
		subtitle_label.modulate.a = 0.62 + sin(_time * 3.1) * 0.25
	for i in range(decorative_tiles.size()):
		var tile := decorative_tiles[i]
		tile.position.y = 104.0 + sin(_time * (1.1 + i * 0.09) + i) * 10.0 + (i % 2) * 34.0
		tile.rotation_degrees = -10.0 + i * 4.0 + sin(_time + i) * 3.0


func _build_menu() -> void:
	for child in get_children():
		child.queue_free()
	decorative_tiles.clear()

	var background: LayeredBackground = LayeredBackgroundScript.new()
	background.name = "BackgroundLayer"
	background.variant = "main_menu"
	add_child(background)

	var decoration_layer := Control.new()
	decoration_layer.name = "DecorationLayer"
	decoration_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(decoration_layer)

	var interact_layer := Control.new()
	interact_layer.name = "InteractionLayer"
	interact_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(interact_layer)

	var fx_layer := Control.new()
	fx_layer.name = "FxLayer"
	fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fx_layer)

	var title_mark := Label.new()
	title_mark.name = "VerticalSealMark"
	title_mark.text = "三\n国"
	title_mark.position = Vector2(18, 22)
	title_mark.add_theme_font_size_override("font_size", 20)
	title_mark.add_theme_color_override("font_color", Color(1.0, 0.18, 0.12))
	decoration_layer.add_child(title_mark)

	main_title = Label.new()
	main_title.name = "MainTitle"
	main_title.text = "Sangoku\nMahjong"
	main_title.position = Vector2(50, 36)
	main_title.size = Vector2(310, 110)
	main_title.add_theme_font_size_override("font_size", 41)
	main_title.add_theme_color_override("font_color", Color(1.0, 0.76, 0.18))
	main_title.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	main_title.add_theme_constant_override("shadow_offset_x", 4)
	main_title.add_theme_constant_override("shadow_offset_y", 4)
	interact_layer.add_child(main_title)

	subtitle_label = Label.new()
	subtitle_label.name = "MainSubtitle"
	subtitle_label.text = "Fate favors bold hands."
	subtitle_label.position = Vector2(66, 158)
	subtitle_label.size = Vector2(250, 24)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 13)
	subtitle_label.add_theme_color_override("font_color", Color(0.46, 1.0, 0.64))
	interact_layer.add_child(subtitle_label)

	var menu_panel := PanelContainer.new()
	menu_panel.name = "MainMenuPanel"
	menu_panel.position = Vector2(48, 190)
	menu_panel.size = Vector2(238, 150)
	menu_panel.add_theme_stylebox_override("panel", _panel_box(Color(0.025, 0.04, 0.035, 0.94), Color(0.74, 0.36, 0.10), 2))
	interact_layer.add_child(menu_panel)

	var menu_stack := VBoxContainer.new()
	menu_stack.name = "MainMenuButtonStack"
	menu_stack.add_theme_constant_override("separation", 8)
	menu_panel.add_child(menu_stack)

	var start_button := _menu_button("StartRunButton", "Start Run", Vector2(190, 30))
	start_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/scenes/battle/battle.tscn")
	)
	menu_stack.add_child(start_button)
	menu_stack.add_child(_menu_button("CollectionButton", "Collection", Vector2(190, 26), true))
	menu_stack.add_child(_menu_button("OptionsButton", "Options", Vector2(190, 26), true))
	var quit_button := _menu_button("QuitButton", "Quit", Vector2(190, 26))
	quit_button.pressed.connect(func() -> void: get_tree().quit())
	menu_stack.add_child(quit_button)

	var glow_label := Label.new()
	glow_label.name = "RightMarqueeText"
	glow_label.text = "EPIC CHAIN   xMULT   GOLDEN SET"
	glow_label.position = Vector2(342, 44)
	glow_label.size = Vector2(260, 26)
	glow_label.rotation_degrees = -3.0
	glow_label.add_theme_font_size_override("font_size", 14)
	glow_label.add_theme_color_override("font_color", Color(1.0, 0.32, 0.18))
	fx_layer.add_child(glow_label)

	var symbols := ["万", "筒", "索", "東", "南", "白", "中"]
	for i in range(symbols.size()):
		var tile := Label.new()
		tile.name = "MenuDecorTile_%02d" % i
		tile.text = symbols[i]
		tile.position = Vector2(350 + i * 34, 104 + (i % 2) * 34)
		tile.size = Vector2(34, 42)
		tile.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tile.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tile.add_theme_font_size_override("font_size", 26)
		tile.add_theme_color_override("font_color", [Color(0.95, 0.16, 0.14), Color(0.2, 0.75, 1.0), Color(0.2, 1.0, 0.48)][i % 3])
		tile.add_theme_stylebox_override("normal", _panel_box(Color(0.94, 0.82, 0.56, 0.95), Color(0.38, 0.14, 0.05), 2))
		decoration_layer.add_child(tile)
		decorative_tiles.append(tile)


func _menu_button(node_name: String, label_text: String, min_size: Vector2, disabled := false) -> Button:
	var button: AnimatedButton = AnimatedButtonScript.new()
	button.name = node_name
	button.text = label_text
	button.custom_minimum_size = min_size
	button.disabled = disabled
	return button


func _panel_box(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(border_width)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_left = 5
	box.corner_radius_bottom_right = 5
	box.shadow_color = Color(0.0, 0.0, 0.0, 0.58)
	box.shadow_size = 6
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	return box
