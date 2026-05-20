# tests/test_doudizhu_rules.gd
extends GutTest

const HT = DoudizhuRules.HandType

func _mk(suit: String, n: int) -> Card:
	return Card.new(suit, n)

# ---------- Identification tests ----------

func test_single() -> void:
	var cards: Array[Card] = [_mk("spades", 5)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.SINGLE)

func test_pair() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("hearts", 5)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.PAIR)

func test_pair_invalid_different_numbers() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("hearts", 6)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.INVALID)

func test_triple() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("hearts", 5), _mk("clubs", 5)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.TRIPLE)

func test_triple_one() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("hearts", 5), _mk("clubs", 5), _mk("diamonds", 9)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.TRIPLE_ONE)

func test_triple_pair() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("hearts", 5), _mk("clubs", 5), _mk("diamonds", 9), _mk("hearts", 9)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.TRIPLE_PAIR)

func test_straight_5() -> void:
	var cards: Array[Card] = [_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 5), _mk("diamonds", 6), _mk("hearts", 7)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.STRAIGHT)

func test_straight_with_2_invalid() -> void:
	var cards: Array[Card] = [_mk("spades", 11), _mk("hearts", 12), _mk("clubs", 13), _mk("diamonds", 14), _mk("hearts", 15)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.INVALID)

func test_consecutive_pairs() -> void:
	var cards: Array[Card] = [
		_mk("spades", 3), _mk("hearts", 3),
		_mk("spades", 4), _mk("hearts", 4),
		_mk("spades", 5), _mk("hearts", 5),
	]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.CONSECUTIVE_PAIRS)

func test_four_two_pair() -> void:
	var cards: Array[Card] = [
		_mk("spades", 7), _mk("hearts", 7), _mk("clubs", 7), _mk("diamonds", 7),
		_mk("spades", 9), _mk("hearts", 9),
	]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.FOUR_TWO)

func test_four_two_singles() -> void:
	var cards: Array[Card] = [
		_mk("spades", 7), _mk("hearts", 7), _mk("clubs", 7), _mk("diamonds", 7),
		_mk("spades", 9), _mk("hearts", 11),
	]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.FOUR_TWO)

func test_bomb() -> void:
	var cards: Array[Card] = [_mk("spades", 7), _mk("hearts", 7), _mk("clubs", 7), _mk("diamonds", 7)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.BOMB)

func test_royal_bomb() -> void:
	var cards: Array[Card] = [_mk("joker", 16), _mk("joker", 17)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.ROYAL_BOMB)

func test_wild_substitution_makes_pair() -> void:
	var cards: Array[Card] = [_mk("spades", 5), _mk("joker", 16)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.PAIR)

func test_wild_substitution_makes_straight() -> void:
	var cards: Array[Card] = [_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 5), _mk("diamonds", 6), _mk("joker", 16)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.STRAIGHT)

func test_wild_attribute_on_regular_card() -> void:
	var c1 := _mk("spades", 5)
	var c2 := _mk("hearts", 8)
	c2.add_attribute("wild")
	var cards: Array[Card] = [c1, c2]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.PAIR)

func test_invalid_random() -> void:
	var cards: Array[Card] = [_mk("spades", 3), _mk("hearts", 7)]
	assert_eq(DoudizhuRules.identify_hand(cards), HT.INVALID)

# ---------- Comparison tests ----------

func test_higher_single_beats_lower() -> void:
	var atk: Array[Card] = [_mk("spades", 10)]
	var def: Array[Card] = [_mk("hearts", 7)]
	assert_true(DoudizhuRules.can_beat(atk, def))

func test_lower_single_does_not_beat() -> void:
	var atk: Array[Card] = [_mk("spades", 5)]
	var def: Array[Card] = [_mk("hearts", 7)]
	assert_false(DoudizhuRules.can_beat(atk, def))

func test_equal_single_does_not_beat() -> void:
	var atk: Array[Card] = [_mk("spades", 7)]
	var def: Array[Card] = [_mk("hearts", 7)]
	assert_false(DoudizhuRules.can_beat(atk, def))

func test_different_type_cannot_beat() -> void:
	var atk: Array[Card] = [_mk("spades", 10), _mk("hearts", 10)]
	var def: Array[Card] = [_mk("hearts", 7)]
	assert_false(DoudizhuRules.can_beat(atk, def))

func test_triple_one_compare_by_triple() -> void:
	var atk: Array[Card] = [_mk("spades", 9), _mk("hearts", 9), _mk("clubs", 9), _mk("diamonds", 3)]
	var def: Array[Card] = [_mk("spades", 8), _mk("hearts", 8), _mk("clubs", 8), _mk("diamonds", 14)]
	assert_true(DoudizhuRules.can_beat(atk, def))

func test_straight_length_must_match() -> void:
	var atk: Array[Card] = [_mk("spades", 4), _mk("hearts", 5), _mk("clubs", 6), _mk("diamonds", 7), _mk("hearts", 8), _mk("spades", 9)]
	var def: Array[Card] = [_mk("spades", 3), _mk("hearts", 4), _mk("clubs", 5), _mk("diamonds", 6), _mk("hearts", 7)]
	assert_false(DoudizhuRules.can_beat(atk, def))

func test_bomb_beats_any_non_bomb() -> void:
	var atk: Array[Card] = [_mk("spades", 4), _mk("hearts", 4), _mk("clubs", 4), _mk("diamonds", 4)]
	var def: Array[Card] = [_mk("spades", 14), _mk("hearts", 14), _mk("clubs", 14)]
	assert_true(DoudizhuRules.can_beat(atk, def))

func test_higher_bomb_beats_lower_bomb() -> void:
	var atk: Array[Card] = [_mk("spades", 10), _mk("hearts", 10), _mk("clubs", 10), _mk("diamonds", 10)]
	var def: Array[Card] = [_mk("spades", 4), _mk("hearts", 4), _mk("clubs", 4), _mk("diamonds", 4)]
	assert_true(DoudizhuRules.can_beat(atk, def))

func test_royal_bomb_beats_bomb() -> void:
	var atk: Array[Card] = [_mk("joker", 16), _mk("joker", 17)]
	var def: Array[Card] = [_mk("spades", 14), _mk("hearts", 14), _mk("clubs", 14), _mk("diamonds", 14)]
	assert_true(DoudizhuRules.can_beat(atk, def))

func test_bomb_does_not_beat_royal_bomb() -> void:
	var atk: Array[Card] = [_mk("spades", 14), _mk("hearts", 14), _mk("clubs", 14), _mk("diamonds", 14)]
	var def: Array[Card] = [_mk("joker", 16), _mk("joker", 17)]
	assert_false(DoudizhuRules.can_beat(atk, def))

func test_opening_play_beats_empty() -> void:
	var atk: Array[Card] = [_mk("spades", 3)]
	var def: Array[Card] = []
	assert_true(DoudizhuRules.can_beat(atk, def))
