class_name MahjongWall
extends RefCounted

var tiles: Array[Tile] = []


func _init(build_now: bool = true) -> void:
	if build_now:
		reset(false)


func reset(should_shuffle: bool = true, seed: int = 0, include_honors: bool = true) -> void:
	tiles.clear()
	for suit in [Tile.Suit.MAN, Tile.Suit.PIN, Tile.Suit.SOU]:
		for rank in range(1, 10):
			for _copy_index in range(4):
				tiles.append(Tile.new(suit, rank))
	if include_honors:
		for rank in range(1, 5):
			for _copy_index in range(4):
				tiles.append(Tile.wind(rank))
		for rank in range(1, 4):
			for _copy_index in range(4):
				tiles.append(Tile.dragon(rank))
	if should_shuffle:
		shuffle(seed)


func shuffle(seed: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()

	for i in range(tiles.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := tiles[i]
		tiles[i] = tiles[j]
		tiles[j] = tmp


func draw_one() -> Tile:
	if tiles.is_empty():
		return null
	return tiles.pop_front()


func draw(count: int) -> Array[Tile]:
	var drawn: Array[Tile] = []
	for _i in range(count):
		var tile := draw_one()
		if tile == null:
			break
		drawn.append(tile)
	return drawn


func remaining_count() -> int:
	return tiles.size()


func peek(count: int) -> Array[Tile]:
	var result: Array[Tile] = []
	for i in range(min(count, tiles.size())):
		result.append(tiles[i])
	return result
