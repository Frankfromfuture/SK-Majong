class_name Hand
extends RefCounted

const MAX_SIZE := 14

var tiles: Array[Tile] = []
var max_size := MAX_SIZE


func _init(p_max_size: int = MAX_SIZE) -> void:
	max_size = p_max_size


func size() -> int:
	return tiles.size()


func is_full() -> bool:
	return tiles.size() >= max_size


func add_tile(tile: Tile) -> bool:
	if tile == null or is_full():
		return false
	tiles.append(tile)
	return true


func add_tiles(new_tiles: Array) -> int:
	var added := 0
	for tile in new_tiles:
		if add_tile(tile):
			added += 1
	return added


func draw_to_full(wall: MahjongWall) -> int:
	var drawn := 0
	while not is_full() and wall.remaining_count() > 0:
		var tile := wall.draw_one()
		if tile == null:
			break
		add_tile(tile)
		drawn += 1
	return drawn


func remove_tiles(selected_tiles: Array) -> bool:
	var indices: Array[int] = []
	var used_indices := {}

	for selected in selected_tiles:
		var found_index := -1
		for i in range(tiles.size()):
			if used_indices.has(i):
				continue
			if tiles[i].equals_tile(selected):
				found_index = i
				break
		if found_index == -1:
			return false
		indices.append(found_index)
		used_indices[found_index] = true

	indices.sort()
	indices.reverse()
	for index in indices:
		tiles.remove_at(index)
	return true


func sorted_tiles() -> Array[Tile]:
	var copy: Array[Tile] = tiles.duplicate()
	copy.sort_custom(func(a: Tile, b: Tile) -> bool: return a.compare_to(b) < 0)
	return copy


func sort_in_place() -> void:
	tiles.sort_custom(func(a: Tile, b: Tile) -> bool: return a.compare_to(b) < 0)


func to_display_string() -> String:
	var names: Array[String] = []
	for tile in sorted_tiles():
		names.append(tile.display_name())
	return " ".join(names)


func clear() -> void:
	tiles.clear()
