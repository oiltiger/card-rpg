# tests/test_integration.gd
extends GutTest

const HT = DoudizhuRules.HandType
const MAX_TURNS := 2000

func test_ai_vs_ai_battle_completes() -> void:
	var ai1 := AICombatant.new()
	var ai2 := AICombatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(ai1, ai2)

	var turns := 0
	while bs.turn_phase != BattleState.TurnPhase.BATTLE_OVER and turns < MAX_TURNS:
		var attacker: Combatant = bs.current_attacker
		var choice: Dictionary = attacker.choose_card(bs)
		if choice.action == "pass":
			bs.process_pass(attacker)
		else:
			var r := bs.process_play(attacker, choice.cards)
			if not r.valid:
				bs.process_pass(attacker)
		turns += 1
		if bs.current_attacker.hand.is_empty() and bs.last_play.is_empty():
			bs.redeal_if_needed()

	assert_lt(turns, MAX_TURNS, "Battle should complete in < %d turns (got %d)" % [MAX_TURNS, turns])
	assert_eq(bs.turn_phase, BattleState.TurnPhase.BATTLE_OVER)
	var winner: Combatant = bs.get_winner()
	assert_not_null(winner)
	assert_true(winner.hp > 0)
	var loser: Combatant = ai2 if winner == ai1 else ai1
	assert_true(loser.hp <= 0)

func test_ai_vs_ai_resources_accumulate() -> void:
	var ai1 := AICombatant.new()
	var ai2 := AICombatant.new()
	ai1.resource_bar.set_max_values(5, 5, false)
	ai2.resource_bar.set_max_values(5, 5, false)
	var bs := BattleState.new(7)
	bs.start_battle(ai1, ai2)

	var turns := 0
	while bs.turn_phase != BattleState.TurnPhase.BATTLE_OVER and turns < MAX_TURNS:
		var attacker: Combatant = bs.current_attacker
		var choice: Dictionary = attacker.choose_card(bs)
		if choice.action == "pass":
			bs.process_pass(attacker)
		else:
			var r := bs.process_play(attacker, choice.cards)
			if not r.valid:
				bs.process_pass(attacker)
		turns += 1

	var any_resource: int = (ai1.resource_bar.combo_points + ai1.resource_bar.mana
		+ ai2.resource_bar.combo_points + ai2.resource_bar.mana)
	assert_gt(any_resource, 0, "Some resources should be accumulated during a full battle")

func test_empty_hand_settlement_keeps_winner_combo_and_resets_loser() -> void:
	var ai1 := AICombatant.new()
	var ai2 := AICombatant.new()
	ai1.resource_bar.set_max_values(5, 5, false)
	ai2.resource_bar.set_max_values(5, 5, false)
	var bs := BattleState.new(13)
	bs.start_battle(ai1, ai2)

	var c3 := Card.new("spades", 3)
	ai1.hand = Hand.new([c3])
	ai2.hand = Hand.new([Card.new("hearts", 4), Card.new("clubs", 5)])
	bs.current_attacker = ai1
	bs.last_play = PlayedHand.new()
	bs.process_play(ai1, [c3])
	assert_true(ai1.combo_state.active, "Winner combo should continue after emptying hand")
	assert_eq(ai1.resource_bar.combo_points, 0, "First play only seeds combo points")
	assert_false(ai2.combo_state.active, "Loser combo should reset")
