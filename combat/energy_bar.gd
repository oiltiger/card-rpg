# combat/energy_bar.gd
class_name CombatResourceBar
extends RefCounted

var combo_points: int = 0
var max_combo_points: int = 0
var mana: int = 0
var max_mana: int = 0

func _init(p_max_combo_points: int = 0, p_max_mana: int = 0, fill_mana: bool = true) -> void:
	max_combo_points = p_max_combo_points
	max_mana = p_max_mana
	combo_points = 0
	mana = max_mana if fill_mana else 0

func reset(fill_mana: bool = true) -> void:
	combo_points = 0
	mana = max_mana if fill_mana else 0

func set_max_values(p_max_combo_points: int, p_max_mana: int, fill_mana: bool = true) -> void:
	max_combo_points = p_max_combo_points
	max_mana = p_max_mana
	combo_points = min(combo_points, max_combo_points)
	mana = max_mana if fill_mana else min(mana, max_mana)

func gain_combo(amount: int) -> void:
	combo_points = clampi(combo_points + amount, 0, max_combo_points)

func spend_combo(amount: int) -> bool:
	if combo_points < amount:
		return false
	combo_points -= amount
	return true

func clear_combo() -> void:
	combo_points = 0

func gain_mana(amount: int) -> void:
	mana = clampi(mana + amount, 0, max_mana)

func spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true

func on_round_win() -> void:
	gain_mana(1)

func on_round_loss(damage: int) -> void:
	clear_combo()
	gain_mana(max(1, damage / 10))
