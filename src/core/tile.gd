class_name Tile
extends RefCounted

enum Suit {
	MAN,
	PIN,
	SOU,
	WIND,
	DRAGON,
}

const SUIT_NAMES := {
	Suit.MAN: "万",
	Suit.PIN: "饼",
	Suit.SOU: "条",
	Suit.WIND: "风",
	Suit.DRAGON: "箭",
}

const WIND_NAMES := {
	1: "东",
	2: "南",
	3: "西",
	4: "北",
}

const DRAGON_NAMES := {
	1: "中",
	2: "发",
	3: "白",
}

var suit: int
var rank: int


func _init(p_suit: int = Suit.MAN, p_rank: int = 1) -> void:
	assert(p_suit in SUIT_NAMES)
	assert(_is_valid_rank(p_suit, p_rank))
	suit = p_suit
	rank = p_rank


static func make(p_suit: int, p_rank: int) -> Tile:
	return Tile.new(p_suit, p_rank)


static func man(p_rank: int) -> Tile:
	return Tile.new(Suit.MAN, p_rank)


static func pin(p_rank: int) -> Tile:
	return Tile.new(Suit.PIN, p_rank)


static func sou(p_rank: int) -> Tile:
	return Tile.new(Suit.SOU, p_rank)


static func wind(p_rank: int) -> Tile:
	return Tile.new(Suit.WIND, p_rank)


static func dragon(p_rank: int) -> Tile:
	return Tile.new(Suit.DRAGON, p_rank)


static func east() -> Tile:
	return wind(1)


static func south() -> Tile:
	return wind(2)


static func west() -> Tile:
	return wind(3)


static func north() -> Tile:
	return wind(4)


static func red() -> Tile:
	return dragon(1)


static func green() -> Tile:
	return dragon(2)


static func white() -> Tile:
	return dragon(3)


func key() -> String:
	return "%s:%s" % [suit, rank]


func display_name() -> String:
	if suit == Suit.WIND:
		return WIND_NAMES.get(rank, "?")
	if suit == Suit.DRAGON:
		return DRAGON_NAMES.get(rank, "?")
	return "%s%s" % [rank, SUIT_NAMES[suit]]


func is_suited() -> bool:
	return suit == Suit.MAN or suit == Suit.PIN or suit == Suit.SOU


func equals_tile(other: Tile) -> bool:
	return other != null and suit == other.suit and rank == other.rank


func compare_to(other: Tile) -> int:
	if suit != other.suit:
		return suit - other.suit
	return rank - other.rank


func duplicate_tile() -> Tile:
	return Tile.new(suit, rank)


static func _is_valid_rank(p_suit: int, p_rank: int) -> bool:
	match p_suit:
		Suit.MAN, Suit.PIN, Suit.SOU:
			return p_rank >= 1 and p_rank <= 9
		Suit.WIND:
			return p_rank >= 1 and p_rank <= 4
		Suit.DRAGON:
			return p_rank >= 1 and p_rank <= 3
	return false
