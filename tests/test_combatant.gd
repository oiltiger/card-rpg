# tests/test_combatant.gd
extends GutTest

func test_combatant_initial_hp() -> void:
	var c := Combatant.new()
	assert_eq(c.hp, 150)
	assert_eq(c.max_hp, 150)
	assert_eq(c.energy_points, 0)

func test_combatant_has_hand_energy_combo() -> void:
	var c := Combatant.new()
	assert_not_null(c.hand)
	assert_not_null(c.energy_bar)
	assert_not_null(c.combo_state)

func test_use_ultimate_when_no_energy_returns_false() -> void:
	var c := Combatant.new()
	assert_false(c.use_ultimate())
	assert_eq(c.energy_points, 0)

func test_use_ultimate_when_energy_present() -> void:
	var c := Combatant.new()
	c.energy_points = 1
	c.energy_bar.energy_points = 1
	var ok := c.use_ultimate()
	assert_true(ok)
	assert_eq(c.energy_points, 0)

func test_take_damage_reduces_hp_and_gains_energy() -> void:
	var c := Combatant.new()
	c.take_damage(30)
	assert_eq(c.hp, 120)
	assert_eq(c.energy_bar.real_points, 3)

func test_take_damage_clamps_to_zero() -> void:
	var c := Combatant.new()
	c.take_damage(200)
	assert_eq(c.hp, 0)
	assert_true(c.is_dead())

func test_character_data_storage() -> void:
	var cd := CharacterData.new("Hero", "Flame Strike", Callable())
	var c := Combatant.new(cd)
	assert_eq(c.character_data.character_name, "Hero")
	assert_eq(c.character_data.ultimate_description, "Flame Strike")
