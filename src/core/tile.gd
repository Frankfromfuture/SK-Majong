class_name Tile
extends RefCounted

enum Suit {
	MAN,
	PIN,
	SOU,
}

const SUIT_NAMES := {
	Suit.MAN: "万",
	Suit.PIN: "筒",
	Suit.SOU: "索",
}

var suit: int
var rank: int


func _init(p_suit: int = Suit.MAN, p_rank: int = 1) -> void:
	assert(p_suit in SUIT_NAMES)
	assert(p_rank >= 1 and p_rank <= 9)
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


func key() -> String:
	return "%s:%s" % [suit, rank]


func display_name() -> String:
	return "%s%s" % [rank, SUIT_NAMES[suit]]


func equals_tile(other: Tile) -> bool:
	return other != null and suit == other.suit and rank == other.rank


func compare_to(other: Tile) -> int:
	if suit != other.suit:
		return suit - other.suit
	return rank - other.rank


func duplicate_tile() -> Tile:
	return Tile.new(suit, rank)
