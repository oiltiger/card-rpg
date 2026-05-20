# tests/test_energy_combo.gd
extends GutTest

const HT = DoudizhuRules.HandType

# ---------- ComboState tests ----------

func test_first_play_enters_combo() -> void:
	var combo := ComboState.new()
	var ok := combo.check_combo(HT.SINGLE, 1, false)
	assert_true(ok)
	assert_true(combo.active)
	assert_eq(combo.prev_hand_type, HT.SINGLE)
	assert_eq(combo.prev_card_count, 1)

func test_same_type_continues_combo() -> void:
	var combo := ComboState.new()
	combo.check_combo(HT.SINGLE, 1, false)
	var ok := combo.check_combo(HT.SINGLE, 1, false)
	assert_true(ok)

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

# ---------- EnergyBar tests ----------

func test_virtual_points_cap_at_10() -> void:
	var bar := EnergyBar.new()
	bar.add_virtual(7)
	bar.add_virtual(7)
	assert_eq(bar.virtual_points, 10)

func test_round_win_converts_virtual_to_real() -> void:
	var bar := EnergyBar.new()
	bar.add_virtual(5)
	bar.on_round_win()
	assert_eq(bar.virtual_points, 0)
	assert_eq(bar.real_points, 5)
	assert_eq(bar.energy_points, 0)

func test_real_points_overflow_to_energy_points() -> void:
	var bar := EnergyBar.new()
	bar.add_virtual(10)
	bar.add_virtual(5)  # capped at 10
	bar.on_round_win()  # 10 real → +1 energy_point, real=0
	assert_eq(bar.energy_points, 1)
	assert_eq(bar.real_points, 0)

func test_round_loss_clears_virtual_and_keeps_existing_real() -> void:
	var bar := EnergyBar.new()
	bar.add_virtual(7)
	bar.real_points = 5
	bar.on_round_loss(20)  # damage 20 → real += 2
	assert_eq(bar.virtual_points, 0)
	assert_eq(bar.real_points, 7)

func test_taking_damage_adds_real_directly() -> void:
	var bar := EnergyBar.new()
	bar.add_real_from_damage(30)
	assert_eq(bar.real_points, 3)

func test_taking_damage_overflows_to_energy_points() -> void:
	var bar := EnergyBar.new()
	bar.real_points = 8
	bar.add_real_from_damage(50)  # +5 → 13 → -10 = 3, +1 energy_point
	assert_eq(bar.real_points, 3)
	assert_eq(bar.energy_points, 1)

func test_combo_broken_then_round_win_still_accumulates() -> void:
	var combo := ComboState.new()
	var bar := EnergyBar.new()
	combo.check_combo(HT.SINGLE, 1, false)
	bar.add_virtual(1)
	combo.check_combo(HT.PAIR, 2, false)
	bar.add_virtual(2)
	var ok := combo.check_combo(HT.TRIPLE_PAIR, 5, false)
	assert_false(ok)
	bar.convert_virtual_to_real()
	assert_eq(bar.real_points, 3)
