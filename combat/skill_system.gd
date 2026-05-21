# combat/skill_system.gd
class_name SkillSystem
extends RefCounted

static func bonus_damage(combatant, hand_type: int, cards: Array[Card]) -> int:
	if combatant.character_data == null:
		return 0
	match combatant.character_data.passive_id:
		"warrior_damage":
			if hand_type == DoudizhuRules.HandType.BOMB or hand_type == DoudizhuRules.HandType.FOUR_TWO:
				return 10
	return 0

static func bonus_virtual(combatant, cards: Array[Card]) -> int:
	if combatant.character_data == null:
		return 0
	if combatant.character_data.passive_id != "wild_virtual":
		return 0
	for c in cards:
		if c.is_wild():
			return 1
	return 0

static func after_valid_play(combatant) -> void:
	if combatant.character_data == null:
		return
	if combatant.character_data.passive_id != "monk_combo":
		return
	combatant.combo_play_count += 1
	if combatant.combo_play_count % 3 == 0:
		combatant.energy_bar.add_real_from_damage(10)
		combatant.energy_points = combatant.energy_bar.energy_points

static func use_ultimate(user, target = null, rng: RandomNumberGenerator = null) -> bool:
	if user.energy_points <= 0:
		return false
	user.energy_points -= 1
	user.energy_bar.energy_points = user.energy_points
	if user.character_data == null:
		if target != null:
			target.take_damage(20)
		return true

	match user.character_data.ultimate_id:
		"warrior_strike":
			if target != null:
				target.take_damage(40)
		"make_wild":
			_make_random_normal_card_wild(user, rng)
		"reflect_next":
			user.reflect_next_damage = true
		_:
			if target != null:
				target.take_damage(20)
	return true

static func can_make_card_wild(user, card: Card) -> bool:
	if user == null or user.hand == null or card == null:
		return false
	if card.suit == "joker" or card.is_wild():
		return false
	return card in user.hand.get_cards()

static func make_card_wild(user, card: Card) -> bool:
	if not can_make_card_wild(user, card):
		return false
	card.add_attribute("wild")
	return true

static func spend_ultimate_energy(user) -> bool:
	if user.energy_points <= 0:
		return false
	user.energy_points -= 1
	user.energy_bar.energy_points = user.energy_points
	return true

static func _make_random_normal_card_wild(user, rng: RandomNumberGenerator = null) -> void:
	var candidates: Array[Card] = []
	for c in user.hand.get_cards():
		if c.suit != "joker" and not c.is_wild():
			candidates.append(c)
	if candidates.is_empty():
		return
	var index := 0
	if rng != null:
		index = rng.randi_range(0, candidates.size() - 1)
	make_card_wild(user, candidates[index])
