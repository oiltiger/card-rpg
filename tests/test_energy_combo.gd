# tests/test_energy_combo.gd
extends GutTest

const HT = DoudizhuRules.HandType
const CombatResourceBarRef = preload("res://combat/energy_bar.gd")

func test_first_play_enters_combo() -> void:
	var combo := ComboState.new()
	var ok := combo.check_combo(HT.SINGLE, 1, false)
	assert_false(ok)
	assert_true(combo.active)
	assert_eq(combo.prev_hand_type, HT.SINGLE)
	assert_eq(combo.prev_card_count, 1)
	assert_eq(combo.chain_count, 1)

func test_same_type_continues_combo() -> void:
	var combo := ComboState.new()
	combo.check_combo(HT.SINGLE, 1, false)
	var ok := combo.check_combo(HT.SINGLE, 1, false)
	assert_true(ok)
	assert_eq(combo.chain_count, 2)

func test_count_plus_one_continues_combo() -> void:
	var combo := ComboState.new()
	combo.check_combo(HT.SINGLE, 1, false)
	var ok := combo.check_combo(HT.PAIR, 2, false)
	assert_true(ok)
	assert_eq(combo.prev_card_count, 2)

func test_wild_card_continues_combo() -> void:
	var combo := ComboState.new()
	combo.check_combo(HT.SINGLE, 1, false)
	var ok := combo.check_combo(HT.TRIPLE_PAIR, 5, true)
	assert_true(ok)

func test_combo_broken_returns_false() -> void:
	var combo := ComboState.new()
	combo.check_combo(HT.PAIR, 2, false)
	var ok := combo.check_combo(HT.TRIPLE_PAIR, 5, false)
	assert_false(ok)

func test_combo_points_cap_at_max() -> void:
	var bar := CombatResourceBarRef.new(5, 3)
	bar.gain_combo(3)
	bar.gain_combo(4)
	assert_eq(bar.combo_points, 5)

func test_spend_combo_points() -> void:
	var bar := CombatResourceBarRef.new(5, 3)
	bar.gain_combo(4)
	assert_true(bar.spend_combo(3))
	assert_eq(bar.combo_points, 1)
	assert_false(bar.spend_combo(2))

func test_mana_starts_full_for_testing() -> void:
	var bar := CombatResourceBarRef.new(5, 8)
	assert_eq(bar.mana, 8)

func test_spend_and_gain_mana() -> void:
	var bar := CombatResourceBarRef.new(5, 8)
	assert_true(bar.spend_mana(4))
	assert_eq(bar.mana, 4)
	bar.gain_mana(10)
	assert_eq(bar.mana, 8)

func test_round_loss_clears_combo_and_gains_mana() -> void:
	var bar := CombatResourceBarRef.new(5, 8, false)
	bar.gain_combo(5)
	bar.on_round_loss(30)
	assert_eq(bar.combo_points, 0)
	assert_eq(bar.mana, 3)

func test_round_win_gains_one_mana() -> void:
	var bar := CombatResourceBarRef.new(5, 8, false)
	bar.on_round_win()
	assert_eq(bar.mana, 1)
