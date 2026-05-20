# combat/energy_bar.gd
class_name EnergyBar
extends RefCounted

var virtual_points: int = 0   # 0..10, accumulates during a combo
var real_points: int = 0      # 0..9, real energy
var energy_points: int = 0    # 集气点, each 10 real_points = 1 energy_point

func reset() -> void:
	virtual_points = 0
	real_points = 0
	energy_points = 0

# Called every time a card is played while combo is active.
func add_virtual(amount: int) -> void:
	virtual_points = min(virtual_points + amount, 10)

# Combo broken: convert virtual to real (cap and overflow into energy_points).
func convert_virtual_to_real() -> void:
	real_points += virtual_points
	virtual_points = 0
	while real_points >= 10:
		real_points -= 10
		energy_points += 1

# Round won by this attacker: virtual→real and accumulate energy_points.
func on_round_win() -> void:
	convert_virtual_to_real()

# Round lost (took damage): clear all, refill real from damage//10.
func on_round_loss(damage: int) -> void:
	virtual_points = 0
	add_real_from_damage(damage)

# Direct real-point gain from taking damage (bypasses virtual).
func add_real_from_damage(damage: int) -> void:
	real_points += damage / 10  # integer division
	while real_points >= 10:
		real_points -= 10
		energy_points += 1
