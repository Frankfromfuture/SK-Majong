extends Control

const MAP_PATH := "res://characters/warlord1/assets/parts/warlord1_parts_map.json"
const CUT_DIR := "res://characters/warlord1/assets/cut"
const DEV_SCENE := "res://characters/warlord1/dev/Warlord1DevScene.tscn"
const BATTLE_SCENE := "res://src/scenes/battle/battle.tscn"

@onready var status_label: Label = $RootMargin/MainVBox/TopBar/StatusLabel
@onready var cut_list: ItemList = $RootMargin/MainVBox/MainSplit/CutPanel/CutVBox/CutList
@onready var preview_name_label: Label = $RootMargin/MainVBox/MainSplit/CutPanel/CutVBox/PreviewNameLabel
@onready var preview_texture: TextureRect = $RootMargin/MainVBox/MainSplit/CutPanel/CutVBox/PreviewTexture
@onready var category_option: OptionButton = $RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/ControlsRow/CategoryOption
@onready var part_option: OptionButton = $RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/ControlsRow/PartOption
@onready var preview_text: TextEdit = $RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/PreviewText

var _map_data: Dictionary = {}
var _cut_files := PackedStringArray()
var _categories := ["rider", "horse", "weapon", "effects"]


func _ready() -> void:
	_bind_top_buttons()
	_bind_action_buttons()
	cut_list.item_selected.connect(_on_cut_item_selected)
	_load_all()


func _bind_top_buttons() -> void:
	$RootMargin/MainVBox/TopBar/AutoMatchButton.pressed.connect(_on_auto_match)
	$RootMargin/MainVBox/TopBar/SaveButton.pressed.connect(_on_save)
	$RootMargin/MainVBox/TopBar/OpenDevButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(DEV_SCENE)
	)
	$RootMargin/MainVBox/TopBar/BackBattleButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file(BATTLE_SCENE)
	)


func _bind_action_buttons() -> void:
	$RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/ControlsRow/AssignButton.pressed.connect(_on_assign)
	$RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/ControlsRow/AppendFrameButton.pressed.connect(_on_append_frame)
	$RootMargin/MainVBox/MainSplit/MapPanel/MapVBox/ControlsRow/ClearButton.pressed.connect(_on_clear)
	category_option.item_selected.connect(func(_idx: int) -> void:
		_rebuild_part_option()
	)


func _load_all() -> void:
	_load_map()
	_load_cut_files()
	_rebuild_category_option()
	_rebuild_part_option()
	_refresh_preview()
	_set_status("Loaded")


func _load_map() -> void:
	if not FileAccess.file_exists(MAP_PATH):
		_map_data = {}
		return
	var file := FileAccess.open(MAP_PATH, FileAccess.READ)
	if file == null:
		_map_data = {}
		return
	var parsed = JSON.parse_string(file.get_as_text())
	_map_data = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func _load_cut_files() -> void:
	_cut_files.clear()
	cut_list.clear()
	var dir := DirAccess.open(CUT_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if name.get_extension().to_lower() == "png":
			_cut_files.append(name)
	dir.list_dir_end()
	_cut_files.sort()
	for f in _cut_files:
		cut_list.add_item(f)
	if cut_list.item_count > 0:
		cut_list.select(0)
		_on_cut_item_selected(0)


func _rebuild_category_option() -> void:
	category_option.clear()
	for c in _categories:
		category_option.add_item(c)
	category_option.select(0)


func _rebuild_part_option() -> void:
	part_option.clear()
	var category: String = _current_category()
	var section: Dictionary = _map_data.get(category, {})
	if typeof(section) != TYPE_DICTIONARY:
		return
	var keys: PackedStringArray = PackedStringArray(section.keys())
	keys.sort()
	for k in keys:
		part_option.add_item(k)
	if part_option.item_count > 0:
		part_option.select(0)


func _selected_file() -> String:
	var selected: PackedInt32Array = cut_list.get_selected_items()
	if selected.is_empty():
		return ""
	return cut_list.get_item_text(selected[0])


func _on_cut_item_selected(index: int) -> void:
	if index < 0 or index >= cut_list.item_count:
		return
	var name := cut_list.get_item_text(index)
	var tex := load("%s/%s" % [CUT_DIR, name]) as Texture2D
	preview_texture.texture = tex
	preview_name_label.text = "Preview: %s" % name


func _current_category() -> String:
	var idx: int = maxi(0, category_option.selected)
	return category_option.get_item_text(idx)


func _current_key() -> String:
	var idx: int = maxi(0, part_option.selected)
	return part_option.get_item_text(idx)


func _on_assign() -> void:
	var file := _selected_file()
	if file.is_empty():
		_set_status("Select a PNG first")
		return
	var category := _current_category()
	var key := _current_key()
	if category == "effects":
		_set_status("Use Append Frame for effects")
		return
	var section: Dictionary = _map_data.get(category, {})
	section[key] = file
	_map_data[category] = section
	_refresh_preview()
	_set_status("Assigned %s -> %s/%s" % [file, category, key])


func _on_append_frame() -> void:
	var file := _selected_file()
	if file.is_empty():
		_set_status("Select a PNG first")
		return
	var category := _current_category()
	var key := _current_key()
	if category != "effects":
		_set_status("Append Frame only works in effects category")
		return
	var section: Dictionary = _map_data.get(category, {})
	var frames: Array = section.get(key, [])
	if not frames.has(file):
		frames.append(file)
		frames.sort()
	section[key] = frames
	_map_data[category] = section
	_refresh_preview()
	_set_status("Appended %s -> effects/%s" % [file, key])


func _on_clear() -> void:
	var category := _current_category()
	var key := _current_key()
	var section: Dictionary = _map_data.get(category, {})
	if category == "effects":
		section[key] = []
	else:
		section[key] = ""
	_map_data[category] = section
	_refresh_preview()
	_set_status("Cleared %s/%s" % [category, key])


func _on_auto_match() -> void:
	_auto_match_section("rider")
	_auto_match_section("horse")
	_auto_match_section("weapon")
	_auto_match_effects()
	_refresh_preview()
	_set_status("Auto matched by filename keywords")


func _auto_match_section(category: String) -> void:
	var section: Dictionary = _map_data.get(category, {})
	for key in section.keys():
		if str(section[key]).strip_edges() != "":
			continue
		for f in _cut_files:
			if f.to_lower().find(String(key).to_lower()) >= 0:
				section[key] = f
				break
	_map_data[category] = section


func _auto_match_effects() -> void:
	var section: Dictionary = _map_data.get("effects", {})
	for key in section.keys():
		var frames: Array = section.get(key, [])
		if not frames.is_empty():
			continue
		var matched := []
		for f in _cut_files:
			if f.to_lower().find(String(key).to_lower()) >= 0:
				matched.append(f)
		matched.sort()
		section[key] = matched
	_map_data["effects"] = section


func _on_save() -> void:
	var file := FileAccess.open(MAP_PATH, FileAccess.WRITE)
	if file == null:
		_set_status("Save failed")
		return
	file.store_string(JSON.stringify(_map_data, "\t"))
	file.close()
	_set_status("Saved: %s" % MAP_PATH)


func _refresh_preview() -> void:
	preview_text.text = JSON.stringify(_map_data, "\t")


func _set_status(msg: String) -> void:
	status_label.text = msg
