# card_engine/card.gd
class_name Card
extends RefCounted

# suit: "spades" | "hearts" | "diamonds" | "clubs" | "joker"
# number: 3..15 for normal cards (J=11, Q=12, K=13, A=14, 2=15)
#          16 = small joker, 17 = big joker
var suit: String = ""
var number: int = 0
var attributes: Array[String] = []

func _init(p_suit: String, p_number: int) -> void:
	suit = p_suit
	number = p_number
	attributes = []
	if number == 16 or number == 17:
		attributes.append("wild")

func is_wild() -> bool:
	return "wild" in attributes

func add_attribute(attr: String) -> void:
	if not attr in attributes:
		attributes.append(attr)

func remove_attribute(attr: String) -> void:
	attributes.erase(attr)

func _to_string() -> String:
	return "Card(%s,%d,%s)" % [suit, number, str(attributes)]
