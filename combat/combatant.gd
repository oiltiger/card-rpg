# combat/combatant.gd
class_name Combatant
extends RefCounted

var hp: int = 150
var max_hp: int = 150
var hand: Hand = null
var energy_bar: EnergyBar = null
var combo_state: ComboState = null
var energy_points: int = 0  # mirror of energy_bar.energy_points for convenience
var character_data: CharacterData = null

func _init(p_character_data: CharacterData = null) -> void:
	hp = 150
	max_hp = 150
	hand = Hand.new()
	energy_bar = EnergyBar.new()
	combo_state = ComboState.new()
	energy_points = 0
	character_data = p_character_data

# Abstract — override in HumanCombatant and AICombatant.
# Returns: { "action": "play" | "pass", "cards": Array[Card] }
func choose_card(_battle_state) -> Dictionary:
	return {"action": "pass", "cards": []}

# Apply HP delta. Returns true if combatant fainted (hp <= 0).
func take_damage(amount: int) -> bool:
	hp -= amount
	if hp < 0:
		hp = 0
	energy_bar.add_real_from_damage(amount)
	energy_points = energy_bar.energy_points
	return hp <= 0

func is_dead() -> bool:
	return hp <= 0

# Spend 1 energy point and return whether the ultimate fires.
func use_ultimate() -> bool:
	if energy_points <= 0:
		return false
	energy_points -= 1
	energy_bar.energy_points = energy_points
	return true
