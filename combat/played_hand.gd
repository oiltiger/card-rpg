# combat/played_hand.gd
class_name PlayedHand
extends RefCounted

var hand_type: int = 0          # DoudizhuRules.HandType
var cards: Array[Card] = []
var damage: int = 0
var combatant_ref: Combatant = null

func _init(p_type: int = 0, p_cards: Array[Card] = [], p_damage: int = 0, p_combatant: Combatant = null) -> void:
	hand_type = p_type
	cards = p_cards.duplicate()
	damage = p_damage
	combatant_ref = p_combatant

func is_empty() -> bool:
	return cards.is_empty()
