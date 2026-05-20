# card_engine/deck.gd
class_name Deck
extends RefCounted

var cards: Array[Card] = []

func _init() -> void:
	build_full_deck()

func build_full_deck() -> void:
	cards = []
	var suits := ["spades", "hearts", "diamonds", "clubs"]
	for s in suits:
		for n in range(3, 16):  # 3..15 inclusive
			cards.append(Card.new(s, n))
	cards.append(Card.new("joker", 16))  # small joker
	cards.append(Card.new("joker", 17))  # big joker

func shuffle_deck(rng: RandomNumberGenerator = null) -> void:
	if rng == null:
		cards.shuffle()
	else:
		var n := cards.size()
		for i in range(n - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp := cards[i]
			cards[i] = cards[j]
			cards[j] = tmp

func deal(count: int) -> Array[Card]:
	var dealt: Array[Card] = []
	for i in range(count):
		if cards.size() > 0:
			dealt.append(cards.pop_back())
	return dealt

func size() -> int:
	return cards.size()

func reset() -> void:
	build_full_deck()
