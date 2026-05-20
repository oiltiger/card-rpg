# combat/battle_state.gd
class_name BattleState
extends RefCounted

enum TurnPhase {
	WAITING_PLAY,
	WAITING_RESPONSE,
	ROUND_END,
	BATTLE_OVER,
}

var player: Combatant = null
var enemy: Combatant = null
var current_attacker: Combatant = null
var last_play: PlayedHand = null  # last non-pass play (the one to beat)
var round_number: int = 0
var turn_phase: int = TurnPhase.WAITING_PLAY
var rng: RandomNumberGenerator = null

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
	var p1_cards := d.deal(17)
	var p2_cards := d.deal(17)
	player.hand = Hand.new(p1_cards)
	enemy.hand = Hand.new(p2_cards)

func redeal_if_needed() -> bool:
	if player.hand.is_empty() and enemy.hand.is_empty():
		_deal_initial()
		round_number += 1
		last_play = PlayedHand.new()
		return true
	return false

func _other(c: Combatant) -> Combatant:
	return enemy if c == player else player

# Process a play (cards). Returns result dict.
# Result: { valid, damage, combo_continued, virtual_added, hand_type }
func process_play(combatant: Combatant, cards: Array[Card]) -> Dictionary:
	var result := {
		"valid": false,
		"damage": 0,
		"combo_continued": false,
		"virtual_added": 0,
		"hand_type": DoudizhuRules.HandType.INVALID,
		"penalty_damage": 0,
		"battle_over": false,
	}

	var hand_type := DoudizhuRules.identify_hand(cards)
	if hand_type == DoudizhuRules.HandType.INVALID:
		return result

	# Must beat last_play (unless last_play empty = opening)
	if not last_play.is_empty():
		if not DoudizhuRules.can_beat(cards, last_play.cards):
			return result

	# Remove cards from hand
	if not combatant.hand.remove_cards(cards):
		return result

	result.valid = true
	result.hand_type = hand_type
	var damage := CardToAction.compute_damage(hand_type, cards.size())
	result.damage = damage

	# Combo check
	var has_wild := false
	for c in cards:
		if c.is_wild():
			has_wild = true
			break
	var combo_ok := combatant.combo_state.check_combo(hand_type, cards.size(), has_wild)
	result.combo_continued = combo_ok
	if combo_ok:
		combatant.energy_bar.add_virtual(cards.size())
		result.virtual_added = cards.size()
	else:
		# Combo broken — convert, reset, start fresh
		combatant.energy_bar.convert_virtual_to_real()
		combatant.combo_state.reset()
		combatant.combo_state.check_combo(hand_type, cards.size(), has_wild)
		combatant.energy_bar.add_virtual(cards.size())
		combatant.energy_points = combatant.energy_bar.energy_points

	# Record this play as the new last_play
	last_play = PlayedHand.new(hand_type, cards, damage, combatant)

	# Swap attacker — defender must respond
	current_attacker = _other(combatant)
	turn_phase = TurnPhase.WAITING_RESPONSE

	if combatant.hand.is_empty():
		var other := _other(combatant)
		if not other.hand.is_empty():
			# Opponent still has cards — apply penalty damage
			var penalty := other.hand.size() * 10
			other.take_damage(penalty)
			result["penalty_damage"] = penalty
			# Combo: finisher keeps state, opponent resets
			other.combo_state.reset()
			other.energy_bar.on_round_loss(penalty)
			other.energy_points = other.energy_bar.energy_points
			combatant.energy_points = combatant.energy_bar.energy_points
			# Redeal both and start fresh round
			_deal_initial()
			round_number += 1
			last_play = PlayedHand.new()
			current_attacker = combatant
			turn_phase = TurnPhase.WAITING_PLAY
			if other.is_dead():
				turn_phase = TurnPhase.BATTLE_OVER
				result["battle_over"] = true
		else:
			redeal_if_needed()
	return result

# Process a pass. Returns { damage_taken, hp_remaining, battle_over, round_ended }
func process_pass(combatant: Combatant) -> Dictionary:
	var result := {
		"damage_taken": 0,
		"hp_remaining": combatant.hp,
		"battle_over": false,
		"round_ended": false,
	}

	# If no last_play (opening), passing is illegal — return as no-op
	if last_play.is_empty():
		return result

	var dmg: int = last_play.damage
	var attacker: Combatant = last_play.combatant_ref
	var dead := combatant.take_damage(dmg)
	result.damage_taken = dmg
	result.hp_remaining = combatant.hp
	result.round_ended = true

	# Energy settlement
	attacker.energy_bar.on_round_win()
	attacker.energy_points = attacker.energy_bar.energy_points
	combatant.energy_bar.on_round_loss(dmg)
	combatant.energy_points = combatant.energy_bar.energy_points
	# Reset combo states for both
	attacker.combo_state.reset()
	combatant.combo_state.reset()

	# Round end housekeeping
	round_number += 1
	last_play = PlayedHand.new()
	current_attacker = attacker  # winner starts next round
	turn_phase = TurnPhase.WAITING_PLAY

	if dead:
		turn_phase = TurnPhase.BATTLE_OVER
		result.battle_over = true

	# If redeal didn't happen but winner has no cards, give turn to opponent who has cards.
	if not redeal_if_needed() and current_attacker.hand.is_empty():
		current_attacker = _other(current_attacker)

	return result

func get_winner() -> Combatant:
	if player.is_dead():
		return enemy
	if enemy.is_dead():
		return player
	return null
