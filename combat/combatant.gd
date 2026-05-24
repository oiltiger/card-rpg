# combat/combatant.gd
class_name Combatant
extends RefCounted

const SkillSystemRef = preload("res://combat/skill_system.gd")
const CombatResourceBarRef = preload("res://combat/energy_bar.gd")

var hp: int = 150
var max_hp: int = 150
var hand: Hand = null
var resource_bar = null
var combo_state: ComboState = null
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
	resource_bar = CombatResourceBarRef.new(_character_max_combo(), _character_max_mana(), true)
	combo_state = ComboState.new()
	combo_play_count = 0
	reflect_next_damage = false

func set_character(data: CharacterData) -> void:
	character_data = data
	max_hp = data.max_hp
	hp = max_hp
	resource_bar.set_max_values(_character_max_combo(), _character_max_mana(), true)

func _character_max_combo() -> int:
	return character_data.max_combo_points if character_data != null else 0

func _character_max_mana() -> int:
	return character_data.max_mana if character_data != null else 0

func choose_card(_battle_state) -> Dictionary:
	return {"action": "pass", "cards": []}

func take_damage(amount: int, grant_mana: bool = true) -> bool:
	hp -= amount
	if hp < 0:
		hp = 0
	if grant_mana:
		resource_bar.gain_mana(max(1, amount / 10))
	return hp <= 0

func is_dead() -> bool:
	return hp <= 0

func use_ultimate(target: Combatant = null) -> bool:
	return SkillSystemRef.use_ultimate(self, target)
