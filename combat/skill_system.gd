# combat/skill_system.gd
class_name SkillSystem
extends RefCounted

static func bonus_damage(combatant, hand_type: int, _cards: Array[Card]) -> int:
	if combatant.character_data == null:
		return 0
	match combatant.character_data.passive_id:
		"warrior_damage":
			if hand_type in [DoudizhuRules.HandType.BOMB, DoudizhuRules.HandType.STRAIGHT_FLUSH, DoudizhuRules.HandType.FOUR_TWO]:
				return 10
	return 0

static func bonus_combo(combatant, cards: Array[Card]) -> int:
	if combatant.character_data == null:
		return 0
	if combatant.character_data.passive_id != "wild_combo":
		return 0
	for c in cards:
		if c.is_wild():
			return 1
	return 0

static func after_valid_play(combatant, combo_continued: bool) -> void:
	if combatant.character_data == null:
		return
	if combatant.character_data.passive_id != "monk_combo":
		return
	combatant.combo_play_count += 1
	if combo_continued and combatant.combo_play_count % 3 == 0:
		combatant.resource_bar.gain_combo(1)

static func use_ultimate(user, target = null, rng: RandomNumberGenerator = null) -> bool:
	if not spend_skill_mana(user):
		return false
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

static func can_use_character_skill(user) -> bool:
	if user == null or user.resource_bar == null or user.character_data == null:
		return false
	return user.resource_bar.mana >= user.character_data.character_skill_mana_cost

static func spend_skill_mana(user) -> bool:
	if user == null or user.resource_bar == null:
		return false
	var cost := 1
	if user.character_data != null:
		cost = user.character_data.character_skill_mana_cost
	return user.resource_bar.spend_mana(cost)

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
