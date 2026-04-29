@tool
extends EditorScript

const RAW_DIR := "res://characters/warlord1/assets/raw_generated"
const CUT_DIR := "res://characters/warlord1/assets/cut"
const INDEX_PATH := "res://characters/warlord1/assets/cut/cut_index.json"
const DEFAULT_PADDING := 12
const GREEN_THRESHOLD := 0.20
const MIN_ALPHA := 0.05
const MIN_COMPONENT_PIXELS := 80


func _run() -> void:
	var report := run_cut()
	print("Warlord1 cutter:", report)


func run_cut() -> Dictionary:
	_ensure_dir(CUT_DIR)
	var source_dir := DirAccess.open(RAW_DIR)
	if source_dir == null:
		return {"ok": false, "reason": "raw_dir_not_found", "path": RAW_DIR}

	var files := PackedStringArray()
	source_dir.list_dir_begin()
	while true:
		var name := source_dir.get_next()
		if name.is_empty():
			break
		if source_dir.current_is_dir():
			continue
		if name.get_extension().to_lower() == "png":
			files.append(name)
	source_dir.list_dir_end()
	files.sort()
	_clear_old_cut_png()

	var index_items: Array = []
	for file_name in files:
		var source_path := "%s/%s" % [RAW_DIR, file_name]
		var cut_items := _cut_one_file(source_path, DEFAULT_PADDING)
		for item in cut_items:
			index_items.append(item)

	var index := {
		"generated_at": Time.get_datetime_string_from_system(),
		"items": index_items
	}
	var file := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(index, "\t"))
		file.close()

	return {
		"ok": true,
		"source_count": files.size(),
		"cut_count": index_items.size(),
		"index_path": INDEX_PATH
	}


func _cut_one_file(source_path: String, padding: int) -> Array:
	var img := Image.new()
	var err := img.load(source_path)
	if err != OK:
		return []

	img.convert(Image.FORMAT_RGBA8)
	_make_green_transparent(img)

	var width := img.get_width()
	var height := img.get_height()
	var visited := PackedByteArray()
	visited.resize(width * height)

	var components: Array = []
	for y in range(height):
		for x in range(width):
			var idx := y * width + x
			if visited[idx] != 0:
				continue
			var alpha := img.get_pixel(x, y).a
			if alpha <= MIN_ALPHA:
				visited[idx] = 1
				continue
			var bounds := _flood_fill_bounds(img, x, y, visited)
			if bounds.size.x > 0 and bounds.size.y > 0 and bounds.size.x * bounds.size.y >= MIN_COMPONENT_PIXELS:
				components.append(bounds)

	var out_items: Array = []
	var base := source_path.get_file().get_basename().to_snake_case()
	for i in range(components.size()):
		var rect: Rect2i = components[i]
		var padded := _pad_rect(rect, width, height, padding)
		var out_img := Image.create(padded.size.x, padded.size.y, false, Image.FORMAT_RGBA8)
		out_img.blit_rect(img, padded, Vector2i.ZERO)
		var out_name := "%s_%03d.png" % [base, i + 1]
		var out_res_path := "%s/%s" % [CUT_DIR, out_name]
		var out_fs_path := ProjectSettings.globalize_path(out_res_path)
		out_img.save_png(out_fs_path)
		out_items.append({
			"source_file": source_path,
			"output_file": out_res_path,
			"component_index": i + 1,
			"crop_rect": {
				"x": padded.position.x,
				"y": padded.position.y,
				"w": padded.size.x,
				"h": padded.size.y
			},
			"size": {
				"w": padded.size.x,
				"h": padded.size.y
			}
		})

	return out_items


func _make_green_transparent(img: Image) -> void:
	var width := img.get_width()
	var height := img.get_height()
	for y in range(height):
		for x in range(width):
			var c := img.get_pixel(x, y)
			if _is_green_screen(c):
				img.set_pixel(x, y, Color(c.r, c.g, c.b, 0.0))


func _is_green_screen(c: Color) -> bool:
	var dr := abs(c.r - 0.0)
	var dg := abs(c.g - 1.0)
	var db := abs(c.b - 0.0)
	var distance := dr + dg + db
	var near_key_green := distance <= GREEN_THRESHOLD and c.g > 0.55
	var dominant_green := c.g > 0.28 and c.g > c.r * 1.2 and c.g > c.b * 1.2 and (c.g - maxf(c.r, c.b)) > 0.07
	return near_key_green or dominant_green


func _flood_fill_bounds(img: Image, sx: int, sy: int, visited: PackedByteArray) -> Rect2i:
	var width := img.get_width()
	var height := img.get_height()
	var min_x := sx
	var min_y := sy
	var max_x := sx
	var max_y := sy
	var stack: Array[Vector2i] = [Vector2i(sx, sy)]

	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		if p.x < 0 or p.x >= width or p.y < 0 or p.y >= height:
			continue
		var idx := p.y * width + p.x
		if visited[idx] != 0:
			continue
		visited[idx] = 1
		if img.get_pixel(p.x, p.y).a <= MIN_ALPHA:
			continue

		min_x = mini(min_x, p.x)
		min_y = mini(min_y, p.y)
		max_x = maxi(max_x, p.x)
		max_y = maxi(max_y, p.y)

		stack.append(Vector2i(p.x + 1, p.y))
		stack.append(Vector2i(p.x - 1, p.y))
		stack.append(Vector2i(p.x, p.y + 1))
		stack.append(Vector2i(p.x, p.y - 1))

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func _pad_rect(rect: Rect2i, max_w: int, max_h: int, padding: int) -> Rect2i:
	var x := maxi(0, rect.position.x - padding)
	var y := maxi(0, rect.position.y - padding)
	var right := mini(max_w, rect.end.x + padding)
	var bottom := mini(max_h, rect.end.y + padding)
	return Rect2i(x, y, right - x, bottom - y)


func _ensure_dir(dir_path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))


func _clear_old_cut_png() -> void:
	var dir := DirAccess.open(CUT_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f.is_empty():
			break
		if dir.current_is_dir():
			continue
		if f.get_extension().to_lower() == "png":
			dir.remove(f)
	dir.list_dir_end()
