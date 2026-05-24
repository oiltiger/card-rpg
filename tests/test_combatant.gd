# tests/test_combatant.gd
extends GutTest

const SkillSystemRef = preload("res://combat/skill_system.gd")

func test_combatant_initial_hp() -> void:
	var c := Combatant.new()
	assert_eq(c.hp, 150)
	assert_eq(c.max_hp, 150)
	assert_eq(c.resource_bar.max_combo_points, 0)
	assert_eq(c.resource_bar.max_mana, 0)

func test_combatant_has_hand_resource_combo() -> void:
	var c := Combatant.new()
	assert_not_null(c.hand)
	assert_not_null(c.resource_bar)
	assert_not_null(c.combo_state)

func test_use_ultimate_without_mana_returns_false() -> void:
	var c := Combatant.new(CharacterData.create("warrior"))
	c.resource_bar.mana = 0
	assert_false(c.use_ultimate())

func test_use_ultimate_spends_mana() -> void:
	var c := Combatant.new(CharacterData.create("warrior"))
	var target := Combatant.new()
	var ok := c.use_ultimate(target)
	assert_true(ok)
	assert_eq(c.resource_bar.mana, 0)
	assert_eq(target.hp, 110)

func test_player_character_resource_values() -> void:
	var warrior := Combatant.new(CharacterData.create("warrior"))
	var mage := Combatant.new(CharacterData.create("mage"))
	var monk := Combatant.new(CharacterData.create("monk"))
	assert_eq(warrior.max_hp, 250)
	assert_eq(warrior.resource_bar.max_combo_points, 3)
	assert_eq(warrior.resource_bar.max_mana, 3)
	assert_eq(mage.max_hp, 150)
	assert_eq(mage.resource_bar.max_combo_points, 5)
	assert_eq(mage.resource_bar.max_mana, 8)
	assert_eq(monk.max_hp, 200)
	assert_eq(monk.resource_bar.max_combo_points, 8)
	assert_eq(monk.resource_bar.max_mana, 5)

func test_mage_ultimate_adds_wild_to_hand() -> void:
	var c := Combatant.new(CharacterData.create("mage"))
	c.hand = Hand.new([Card.new("spades", 5)])
	assert_true(c.use_ultimate())
	assert_true(c.hand.get_cards()[0].is_wild())
	assert_eq(c.resource_bar.mana, 4)

func test_mage_can_make_selected_card_wild() -> void:
	var c := Combatant.new(CharacterData.create("mage"))
	var card := Card.new("spades", 5)
	c.hand = Hand.new([card])
	assert_true(SkillSystemRef.make_card_wild(c, card))
	assert_true(card.is_wild())

func test_mage_cannot_make_joker_wild_by_selection() -> void:
	var c := Combatant.new(CharacterData.create("mage"))
	var joker := Card.new("joker", 16)
	c.hand = Hand.new([joker])
	assert_false(SkillSystemRef.can_make_card_wild(c, joker))

func test_monk_ultimate_arms_reflect() -> void:
	var c := Combatant.new(CharacterData.create("monk"))
	assert_true(c.use_ultimate())
	assert_true(c.reflect_next_damage)
	assert_eq(c.resource_bar.mana, 1)

func test_take_damage_reduces_hp_and_gains_mana() -> void:
	var c := Combatant.new(CharacterData.create("mage"))
	c.resource_bar.mana = 0
	c.take_damage(30)
	assert_eq(c.hp, 120)
	assert_eq(c.resource_bar.mana, 3)

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
