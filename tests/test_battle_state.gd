# tests/test_battle_state.gd
extends GutTest

const HT = DoudizhuRules.HandType

func _mk(suit: String, n: int) -> Card:
	return Card.new(suit, n)

func test_card_to_action_damage_single() -> void:
	assert_eq(CardToAction.compute_damage(HT.SINGLE, 1), 10)

func test_card_to_action_damage_pair() -> void:
	assert_eq(CardToAction.compute_damage(HT.PAIR, 2), 20)

func test_card_to_action_damage_straight_5() -> void:
	assert_eq(CardToAction.compute_damage(HT.STRAIGHT, 5), 50)

func test_card_to_action_damage_bomb() -> void:
	assert_eq(CardToAction.compute_damage(HT.BOMB, 4), 60)

func test_card_to_action_damage_royal_bomb() -> void:
	assert_eq(CardToAction.compute_damage(HT.ROYAL_BOMB, 2), 100)

func test_battle_start_deals_17_each() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	assert_eq(p1.hand.size(), 17)
	assert_eq(p2.hand.size(), 17)
	assert_eq(bs.discard_pile.size(), 20)
	assert_not_null(bs.current_attacker)

func test_battle_start_deals_unique_54_cards() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var seen := {}
	for c in p1.hand.get_cards() + p2.hand.get_cards() + bs.discard_pile:
		var key := "%s-%d" % [c.suit, c.number]
		assert_false(seen.has(key), "Card should be unique: %s" % key)
		seen[key] = true
	assert_eq(seen.size(), 54)

func test_invalid_play_returns_not_valid() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	p1.hand = Hand.new([_mk("spades", 3), _mk("hearts", 7)])
	var result := bs.process_play(p1, [_mk("spades", 3), _mk("hearts", 7)])
	assert_false(result.valid)

func test_valid_pair_play_that_empties_hand_redeals_and_penalizes_opponent() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 5)
	p1.hand = Hand.new([c1, c2])
	p2.hand = Hand.new([_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 6)])
	var result := bs.process_play(p1, [c1, c2])
	assert_true(result.valid)
	assert_eq(result.damage, 20)
	assert_eq(result.penalty_damage, 30)
	assert_eq(p2.hp, 120)
	assert_eq(p1.hand.size(), 17)
	assert_eq(p2.hand.size(), 17)
	assert_eq(bs.discard_pile.size(), 20)
	assert_true(bs.last_play.is_empty())
	assert_eq(bs.current_attacker, p1)

func test_valid_pair_play_records_last_play_when_hand_not_empty() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 5)
	var spare := _mk("clubs", 9)
	p1.hand = Hand.new([c1, c2, spare])
	var result := bs.process_play(p1, [c1, c2])
	assert_true(result.valid)
	assert_eq(p1.hand.size(), 1)
	assert_eq(bs.last_play.hand_type, HT.PAIR)

func test_pass_applies_damage_to_passer() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 9)
	var c2 := _mk("hearts", 9)
	p1.hand = Hand.new([c1, c2])
	p1.hand.add_card(_mk("clubs", 3))
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	bs.process_play(p1, [c1, c2])
	var pass_result := bs.process_pass(p2)
	assert_eq(pass_result.damage_taken, 20)
	assert_eq(p2.hp, 130)
	assert_false(pass_result.battle_over)

func test_pass_at_battle_over() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	p2.hp = 10
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 9)
	var c2 := _mk("hearts", 9)
	p1.hand = Hand.new([c1, c2])
	p1.hand.add_card(_mk("clubs", 3))
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	bs.process_play(p1, [c1, c2])
	var pass_result := bs.process_pass(p2)
	assert_true(pass_result.battle_over)
	assert_eq(bs.get_winner(), p1)

func test_redeal_when_both_empty() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	p1.hand = Hand.new([])
	p2.hand = Hand.new([])
	var redealt := bs.redeal_if_needed()
	assert_true(redealt)
	assert_eq(p1.hand.size(), 17)
	assert_eq(p2.hand.size(), 17)
	assert_eq(bs.discard_pile.size(), 20)

# ---------- AI tests ----------

func test_ai_plays_smallest_single_when_free_and_opponent_big_hand() -> void:
	var ai := AICombatant.new()
	var opp := Combatant.new()
	ai.hand = Hand.new([_mk("spades", 9), _mk("hearts", 3), _mk("clubs", 11)])
	opp.hand = Hand.new([_mk("spades", 4), _mk("hearts", 4), _mk("clubs", 4),
		_mk("spades", 5), _mk("hearts", 5), _mk("clubs", 5),
		_mk("spades", 6), _mk("hearts", 6), _mk("clubs", 6), _mk("spades", 7)])  # size 10
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new()
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(result.cards.size(), 1)
	assert_eq(result.cards[0].number, 3)

func test_ai_passes_when_cannot_counter() -> void:
	var ai := AICombatant.new()
	var opp := Combatant.new()
	ai.hand = Hand.new([_mk("spades", 3)])
	opp.hand = Hand.new([_mk("spades", 9)])
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new(HT.SINGLE, [_mk("spades", 14)] as Array[Card], 10, opp)
	var result := ai.choose_card(bs)
	assert_eq(result.action, "pass")

func test_ai_counters_with_smallest_higher_card() -> void:
	var ai := AICombatant.new()
	var opp := Combatant.new()
	ai.hand = Hand.new([_mk("spades", 8), _mk("hearts", 11), _mk("clubs", 14)])
	opp.hand = Hand.new([_mk("spades", 5)])
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new(HT.SINGLE, [_mk("spades", 7)] as Array[Card], 10, opp)
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(result.cards[0].number, 8)

func test_ai_uses_bomb_when_opponent_low_hand() -> void:
	var ai := AICombatant.new()
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8), _mk("diamonds", 8),
		_mk("spades", 3)
	])
	opp.hand = Hand.new([_mk("spades", 5), _mk("hearts", 5)])  # size 2
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new()
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(result.cards.size(), 4)  # bomb
