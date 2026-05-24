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

func test_card_to_action_damage_four_two() -> void:
	assert_eq(CardToAction.compute_damage(HT.FOUR_TWO, 6), 70)

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

func test_first_play_starts_combo_but_adds_no_combo_points() -> void:
	var p1 := Combatant.new(CharacterData.create("mage"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	p1.hand = Hand.new([c1, _mk("clubs", 9)])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	var result := bs.process_play(p1, [c1])
	assert_true(result.valid)
	assert_false(result.combo_continued)
	assert_eq(result.combo_added, 0)
	assert_eq(p1.resource_bar.combo_points, 0)

func test_second_linked_play_adds_current_combo_points() -> void:
	var p1 := Combatant.new(CharacterData.create("mage"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 6)
	var c3 := _mk("clubs", 6)
	p1.hand = Hand.new([c1, c2, c3, _mk("clubs", 9)])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	assert_true(bs.process_play(p1, [c1]).valid)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	var result := bs.process_play(p1, [c2, c3])
	assert_true(result.valid)
	assert_true(result.combo_continued)
	assert_eq(result.combo_added, 2)
	assert_eq(p1.resource_bar.combo_points, 2)

func test_broken_combo_clears_points_and_restarts_seed() -> void:
	var p1 := Combatant.new(CharacterData.create("mage"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 6)
	var c3 := _mk("clubs", 6)
	var c4 := _mk("diamonds", 9)
	p1.hand = Hand.new([c1, c2, c3, c4])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	assert_true(bs.process_play(p1, [c1]).valid)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	assert_true(bs.process_play(p1, [c2, c3]).valid)
	assert_eq(p1.resource_bar.combo_points, 2)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	var result := bs.process_play(p1, [c4])
	assert_true(result.valid)
	assert_false(result.combo_continued)
	assert_eq(result.combo_added, 0)
	assert_eq(p1.resource_bar.combo_points, 0)

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
	assert_true(p1.combo_state.active)
	assert_false(p2.combo_state.active)

func test_reflect_prevents_next_pass_damage_and_hits_attacker() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new(CharacterData.create("monk"))
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 9)
	var c2 := _mk("hearts", 9)
	p1.hand = Hand.new([c1, c2, _mk("clubs", 3)])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	p2.reflect_next_damage = true
	bs.process_play(p1, [c1, c2])
	var pass_result := bs.process_pass(p2)
	assert_eq(pass_result.damage_taken, 0)
	assert_eq(pass_result.reflected_damage, 20)
	assert_eq(p2.hp, 200)
	assert_eq(p1.hp, 130)
	assert_false(p2.reflect_next_damage)
	assert_eq(bs.current_attacker, p2)

func test_reflect_can_reverse_empty_hand_penalty() -> void:
	var p1 := Combatant.new()
	var p2 := Combatant.new(CharacterData.create("monk"))
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 5)
	p1.hand = Hand.new([c1, c2])
	p2.hand = Hand.new([_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 6)])
	p2.reflect_next_damage = true
	var result := bs.process_play(p1, [c1, c2])
	assert_true(result.valid)
	assert_eq(result.penalty_damage, 30)
	assert_eq(result.reflected_damage, 30)
	assert_eq(p2.hp, 200)
	assert_eq(p1.hp, 120)
	assert_false(p2.reflect_next_damage)

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

func test_normal_ai_prefers_airplane_over_single_when_free() -> void:
	var ai := AICombatant.new("normal")
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 7), _mk("hearts", 7), _mk("clubs", 7),
		_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8),
		_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 12),
	])
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new()
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(DoudizhuRules.identify_hand(result.cards), HT.AIRPLANE_SINGLE)
	assert_eq(result.cards.size(), 8)

func test_normal_ai_uses_loose_single_without_breaking_straight() -> void:
	var ai := AICombatant.new("normal")
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 5), _mk("diamonds", 6), _mk("spades", 7),
		_mk("clubs", 12),
	])
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new(HT.SINGLE, [_mk("diamonds", 10)] as Array[Card], 10, opp)
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(result.cards.size(), 1)
	assert_eq(result.cards[0].number, 12)

func test_normal_ai_prefers_straight_flush_over_plain_straight() -> void:
	var ai := AICombatant.new("normal")
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 3), _mk("spades", 4), _mk("spades", 5), _mk("spades", 6), _mk("spades", 7),
		_mk("hearts", 8), _mk("clubs", 9), _mk("diamonds", 15),
	])
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new()
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(DoudizhuRules.identify_hand(result.cards), HT.STRAIGHT_FLUSH)

func test_hard_ai_counters_airplane_with_same_type() -> void:
	var ai := AICombatant.new("hard")
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8),
		_mk("spades", 9), _mk("hearts", 9), _mk("clubs", 9),
		_mk("spades", 4), _mk("hearts", 5),
	])
	var target: Array[Card] = [
		_mk("spades", 7), _mk("hearts", 7), _mk("clubs", 7),
		_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8),
		_mk("spades", 3), _mk("hearts", 4),
	]
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new(HT.AIRPLANE_SINGLE, target, 80, opp)
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(DoudizhuRules.identify_hand(result.cards), HT.AIRPLANE_SINGLE)
	assert_true(DoudizhuRules.can_beat(result.cards, target))

func test_hard_ai_uses_bomb_when_opponent_low_hand() -> void:
	var ai := AICombatant.new("hard")
	var opp := Combatant.new()
	ai.hand = Hand.new([
		_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8), _mk("diamonds", 8),
		_mk("spades", 3), _mk("hearts", 4)
	])
	opp.hand = Hand.new([_mk("spades", 5), _mk("hearts", 5)])
	var target: Array[Card] = [
		_mk("spades", 10), _mk("hearts", 10), _mk("clubs", 10), _mk("diamonds", 3)
	]
	var bs := BattleState.new(42)
	bs.player = opp
	bs.enemy = ai
	bs.last_play = PlayedHand.new(HT.TRIPLE_ONE, target, 40, opp)
	var result := ai.choose_card(bs)
	assert_eq(result.action, "play")
	assert_eq(DoudizhuRules.identify_hand(result.cards), HT.BOMB)

func test_ai_difficulty_hp_values() -> void:
	assert_eq(AICombatant.new("easy").max_hp, 200)
	assert_eq(AICombatant.new("normal").max_hp, 300)
	assert_eq(AICombatant.new("hard").max_hp, 400)

func test_warrior_passive_adds_bomb_damage() -> void:
	var p1 := Combatant.new(CharacterData.create("warrior"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var cards: Array[Card] = [_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8), _mk("diamonds", 8), _mk("spades", 3)]
	p1.hand = Hand.new(cards)
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	var result := bs.process_play(p1, cards.slice(0, 4))
	assert_true(result.valid)
	assert_eq(result.damage, 70)

func test_mage_passive_adds_combo_for_wild_play() -> void:
	var p1 := Combatant.new(CharacterData.create("mage"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var seed := _mk("diamonds", 3)
	var c1 := _mk("spades", 5)
	var c2 := _mk("joker", 16)
	p1.hand = Hand.new([seed, c1, c2, _mk("clubs", 9)])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	assert_true(bs.process_play(p1, [seed]).valid)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	var result := bs.process_play(p1, [c1, c2])
	assert_true(result.valid)
	assert_eq(result.combo_added, 3)
	assert_eq(p1.resource_bar.combo_points, 3)

func test_monk_passive_adds_combo_every_third_play() -> void:
	var p1 := Combatant.new(CharacterData.create("monk"))
	var p2 := Combatant.new()
	var bs := BattleState.new(42)
	bs.start_battle(p1, p2)
	var c1 := _mk("spades", 3)
	var c2 := _mk("hearts", 4)
	var c3 := _mk("clubs", 5)
	var c4 := _mk("diamonds", 6)
	p1.hand = Hand.new([c1, c2, c3, c4])
	bs.current_attacker = p1
	bs.last_play = PlayedHand.new()
	assert_true(bs.process_play(p1, [c1]).valid)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	assert_true(bs.process_play(p1, [c2]).valid)
	bs.last_play = PlayedHand.new()
	bs.current_attacker = p1
	assert_true(bs.process_play(p1, [c3]).valid)
	assert_eq(p1.resource_bar.combo_points, 3)
