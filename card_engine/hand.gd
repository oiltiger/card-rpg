# card_engine/hand.gd
class_name Hand
extends RefCounted

var cards: Array[Card] = []

func _init(initial: Array[Card] = []) -> void:
	cards = []
	for c in initial:
		cards.append(c)

func add_card(card: Card) -> void:
	cards.append(card)

func add_cards(new_cards: Array[Card]) -> void:
	for c in new_cards:
		cards.append(c)

func remove_card(card: Card) -> bool:
	var idx := cards.find(card)
	if idx == -1:
		return false
	cards.remove_at(idx)
	return true

func remove_cards(to_remove: Array[Card]) -> bool:
	for c in to_remove:
		if not remove_card(c):
			return false
	return true

func size() -> int:
	return cards.size()

func is_empty() -> bool:
	return cards.is_empty()

func clear() -> void:
	cards.clear()

func contains(card: Card) -> bool:
	return card in cards

func sort_by_number() -> void:
	cards.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)

func get_cards() -> Array[Card]:
	return cards.duplicate()

func get_sorted() -> Array[Card]:
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a: Card, b: Card) -> bool:
		return a.number < b.number
	)
	return sorted
