# combat/battle_state.gd
class_name BattleState
extends RefCounted

const SkillSystemRef = preload("res://combat/skill_system.gd")

enum TurnPhase {
	WAITING_PLAY,
	WAITING_RESPONSE,
	ROUND_END,
	BATTLE_OVER,
}

var player: Combatant = null
var enemy: Combatant = null
var current_attacker: Combatant = null
var last_play: PlayedHand = null
var round_number: int = 0
var turn_phase: int = TurnPhase.WAITING_PLAY
var rng: RandomNumberGenerator = null
var discard_pile: Array[Card] = []

func _init(seed_val: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	if seed_val >= 0:
		rng.seed = seed_val
	else:
		rng.randomize()

func start_battle(p1: Combatant, p2: Combatant) -> void:
	player = p1
	enemy = p2
	round_number = 1
	turn_phase = TurnPhase.WAITING_PLAY
	last_play = PlayedHand.new()
	_deal_initial()
	if rng.randi_range(0, 1) == 0:
		current_attacker = player
	else:
		current_attacker = enemy

func _deal_initial() -> void:
	var d := Deck.new()
	d.shuffle_deck(rng)
	player.hand = Hand.new(d.deal(17))
	enemy.hand = Hand.new(d.deal(17))
	discard_pile = d.deal(d.size())

func redeal_if_needed() -> bool:
	if player.hand.is_empty() and enemy.hand.is_empty():
		_deal_initial()
		round_number += 1
		last_play = PlayedHand.new()
		return true
	return false

func _other(c: Combatant) -> Combatant:
	return enemy if c == player else player

func process_play(combatant: Combatant, cards: Array[Card]) -> Dictionary:
	var result := {
		"valid": false,
		"damage": 0,
		"combo_continued": false,
		"combo_added": 0,
		"hand_type": DoudizhuRules.HandType.INVALID,
		"penalty_damage": 0,
		"reflected_damage": 0,
		"battle_over": false,
	}

	var hand_type := DoudizhuRules.identify_hand(cards)
	if hand_type == DoudizhuRules.HandType.INVALID:
		return result
	if not last_play.is_empty() and not DoudizhuRules.can_beat(cards, last_play.cards):
		return result
	if not combatant.hand.remove_cards(cards):
		return result

	result.valid = true
	result.hand_type = hand_type
	var damage: int = CardToAction.compute_damage(hand_type, cards.size()) + SkillSystemRef.bonus_damage(combatant, hand_type, cards)
	result.damage = damage

	var has_wild := false
	for c in cards:
		if c.is_wild():
			has_wild = true
			break
	var combo_ok := combatant.combo_state.check_combo(hand_type, cards.size(), has_wild)
	result.combo_continued = combo_ok
	if not combo_ok:
		combatant.resource_bar.clear_combo()
		combatant.combo_state.reset()
		combatant.combo_state.check_combo(hand_type, cards.size(), has_wild)
	else:
		var combo_gain: int = cards.size() + SkillSystemRef.bonus_combo(combatant, cards)
		combatant.resource_bar.gain_combo(combo_gain)
		result.combo_added = combo_gain
	SkillSystemRef.after_valid_play(combatant, combo_ok)

	last_play = PlayedHand.new(hand_type, cards, damage, combatant)
	current_attacker = _other(combatant)
	turn_phase = TurnPhase.WAITING_RESPONSE

	if combatant.hand.is_empty():
		var other := _other(combatant)
		if not other.hand.is_empty():
			var penalty := other.hand.size() * 10
			var damage_outcome := _apply_damage_or_reflect(other, combatant, penalty)
			result.penalty_damage = penalty
			result.reflected_damage = damage_outcome.reflected_damage
			if damage_outcome.reflected_damage > 0:
				combatant.combo_state.reset()
				combatant.resource_bar.on_round_loss(penalty)
				other.resource_bar.on_round_win()
			else:
				other.combo_state.reset()
				other.resource_bar.on_round_loss(penalty)
			if damage_outcome.dead or damage_outcome.reflected_dead:
				turn_phase = TurnPhase.BATTLE_OVER
				result.battle_over = true
			else:
				_deal_initial()
				round_number += 1
				last_play = PlayedHand.new()
				current_attacker = combatant
				turn_phase = TurnPhase.WAITING_PLAY
		else:
			redeal_if_needed()
	return result

func process_pass(combatant: Combatant) -> Dictionary:
	var result := {
		"damage_taken": 0,
		"reflected_damage": 0,
		"hp_remaining": combatant.hp,
		"battle_over": false,
		"round_ended": false,
	}

	if last_play.is_empty():
		return result

	var dmg: int = last_play.damage
	var attacker: Combatant = last_play.combatant_ref
	var damage_outcome := _apply_damage_or_reflect(combatant, attacker, dmg)
	result.damage_taken = damage_outcome.damage_taken
	result.reflected_damage = damage_outcome.reflected_damage
	result.hp_remaining = combatant.hp
	result.round_ended = true

	if damage_outcome.reflected_damage > 0:
		combatant.resource_bar.on_round_win()
		attacker.combo_state.reset()
		attacker.resource_bar.on_round_loss(dmg)
	else:
		attacker.resource_bar.on_round_win()
		combatant.combo_state.reset()
		combatant.resource_bar.on_round_loss(dmg)

	round_number += 1
	last_play = PlayedHand.new()
	current_attacker = combatant if damage_outcome.reflected_damage > 0 else attacker
	turn_phase = TurnPhase.WAITING_PLAY

	if damage_outcome.dead or damage_outcome.reflected_dead:
		turn_phase = TurnPhase.BATTLE_OVER
		result.battle_over = true

	if not redeal_if_needed() and current_attacker.hand.is_empty():
		current_attacker = _other(current_attacker)

	return result

func _apply_damage_or_reflect(target: Combatant, source: Combatant, amount: int) -> Dictionary:
	var result := {
		"damage_taken": amount,
		"reflected_damage": 0,
		"dead": false,
		"reflected_dead": false,
	}
	if target.reflect_next_damage:
		target.reflect_next_damage = false
		result.damage_taken = 0
		result.reflected_damage = amount
		if source != null:
			result.reflected_dead = source.take_damage(amount, false)
	else:
		result.dead = target.take_damage(amount, false)
	return result

func get_winner() -> Combatant:
	if player.is_dead():
		return enemy
	if enemy.is_dead():
		return player
	return null
