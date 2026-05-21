# combat/combatant.gd
class_name Combatant
extends RefCounted

const SkillSystemRef = preload("res://combat/skill_system.gd")

var hp: int = 150
var max_hp: int = 150
var hand: Hand = null
var energy_bar: EnergyBar = null
var combo_state: ComboState = null
var energy_points: int = 0  # mirror of energy_bar.energy_points for convenience
var character_data: CharacterData = null
var combo_play_count: int = 0
var reflect_next_damage: bool = false

func _init(p_character_data: CharacterData = null) -> void:
	character_data = p_character_data
	if character_data != null:
		max_hp = character_data.max_hp
	else:
		max_hp = 150
	hp = max_hp
	hand = Hand.new()
	energy_bar = EnergyBar.new()
	combo_state = ComboState.new()
	energy_points = 0
	combo_play_count = 0
	reflect_next_damage = false

func set_character(data: CharacterData) -> void:
	character_data = data
	max_hp = data.max_hp
	hp = max_hp

# Abstract — override in HumanCombatant and AICombatant.
# Returns: { "action": "play" | "pass", "cards": Array[Card] }
func choose_card(_battle_state) -> Dictionary:
	return {"action": "pass", "cards": []}

# Apply HP delta. Returns true if combatant fainted (hp <= 0).
func take_damage(amount: int, grant_energy: bool = true) -> bool:
	hp -= amount
	if hp < 0:
		hp = 0
	if grant_energy:
		energy_bar.add_real_from_damage(amount)
		energy_points = energy_bar.energy_points
	return hp <= 0

func is_dead() -> bool:
	return hp <= 0

# Spend 1 energy point and return whether the ultimate fires.
func use_ultimate(target: Combatant = null) -> bool:
	return SkillSystemRef.use_ultimate(self, target)
