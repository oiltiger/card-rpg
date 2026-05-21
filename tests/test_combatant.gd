# tests/test_combatant.gd
extends GutTest

const SkillSystemRef = preload("res://combat/skill_system.gd")

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

func test_use_ultimate_damages_target() -> void:
	var c := Combatant.new()
	var target := Combatant.new()
	c.energy_points = 1
	c.energy_bar.energy_points = 1
	var ok := c.use_ultimate(target)
	assert_true(ok)
	assert_eq(c.energy_points, 0)
	assert_eq(target.hp, 130)

func test_player_character_hp_values() -> void:
	assert_eq(Combatant.new(CharacterData.create("warrior")).max_hp, 250)
	assert_eq(Combatant.new(CharacterData.create("trickster")).max_hp, 150)
	assert_eq(Combatant.new(CharacterData.create("monk")).max_hp, 200)

func test_warrior_ultimate_deals_40_damage() -> void:
	var c := Combatant.new(CharacterData.create("warrior"))
	var target := Combatant.new()
	c.energy_points = 1
	c.energy_bar.energy_points = 1
	assert_true(c.use_ultimate(target))
	assert_eq(target.hp, 110)

func test_trickster_ultimate_adds_wild_to_hand() -> void:
	var c := Combatant.new(CharacterData.create("trickster"))
	c.hand = Hand.new([Card.new("spades", 5)])
	c.energy_points = 1
	c.energy_bar.energy_points = 1
	assert_true(c.use_ultimate())
	assert_true(c.hand.get_cards()[0].is_wild())

func test_trickster_can_make_selected_card_wild() -> void:
	var c := Combatant.new(CharacterData.create("trickster"))
	var card := Card.new("spades", 5)
	c.hand = Hand.new([card])
	assert_true(SkillSystemRef.make_card_wild(c, card))
	assert_true(card.is_wild())

func test_trickster_cannot_make_joker_wild_by_selection() -> void:
	var c := Combatant.new(CharacterData.create("trickster"))
	var joker := Card.new("joker", 16)
	c.hand = Hand.new([joker])
	assert_false(SkillSystemRef.can_make_card_wild(c, joker))

func test_monk_ultimate_arms_reflect() -> void:
	var c := Combatant.new(CharacterData.create("monk"))
	c.energy_points = 1
	c.energy_bar.energy_points = 1
	assert_true(c.use_ultimate())
	assert_true(c.reflect_next_damage)
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
