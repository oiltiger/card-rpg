# tests/test_card_engine.gd
extends GutTest

# ---- Card tests ----

func test_card_normal_has_empty_attributes() -> void:
	var c := Card.new("hearts", 7)
	assert_eq(c.attributes.size(), 0, "Normal card should have no attributes")

func test_card_small_joker_has_wild() -> void:
	var c := Card.new("joker", 16)
	assert_true(c.is_wild(), "Small joker should be wild")
	assert_true("wild" in c.attributes)

func test_card_big_joker_has_wild() -> void:
	var c := Card.new("joker", 17)
	assert_true(c.is_wild(), "Big joker should be wild")

func test_card_normal_is_not_wild() -> void:
	var c := Card.new("spades", 10)
	assert_false(c.is_wild(), "Normal card is not wild")

func test_card_add_attribute() -> void:
	var c := Card.new("hearts", 5)
	c.add_attribute("wild")
	assert_true(c.is_wild(), "Card should be wild after adding wild attribute")

func test_card_add_attribute_no_duplicate() -> void:
	var c := Card.new("joker", 16)  # already has wild
	c.add_attribute("wild")
	assert_eq(c.attributes.size(), 1, "Should not duplicate attribute")

func test_card_remove_attribute() -> void:
	var c := Card.new("joker", 16)
	assert_true(c.is_wild())
	c.remove_attribute("wild")
	assert_false(c.is_wild(), "Should not be wild after removing attribute")

func test_normal_card_given_wild_becomes_wild() -> void:
	var c := Card.new("clubs", 9)
	assert_false(c.is_wild())
	c.add_attribute("wild")
	assert_true(c.is_wild(), "Normal card with wild attribute should be wild")

# ---- Deck tests ----

func test_deck_has_54_cards() -> void:
	var d := Deck.new()
	assert_eq(d.size(), 54, "Full deck should have 54 cards")

func test_deck_has_52_normal_and_2_jokers() -> void:
	var d := Deck.new()
	var joker_count := 0
	var normal_count := 0
	for c in d.cards:
		if c.suit == "joker":
			joker_count += 1
		else:
			normal_count += 1
	assert_eq(joker_count, 2, "Should have 2 jokers")
	assert_eq(normal_count, 52, "Should have 52 normal cards")

func test_deck_deal_17_removes_from_deck() -> void:
	var d := Deck.new()
	var dealt := d.deal(17)
	assert_eq(dealt.size(), 17, "Should deal 17 cards")
	assert_eq(d.size(), 37, "Deck should have 37 remaining")

func test_deck_deal_twice_no_duplicates() -> void:
	var d := Deck.new()
	var hand1 := d.deal(17)
	var hand2 := d.deal(17)
	# Check no card appears in both hands
	for c in hand1:
		assert_false(c in hand2, "No card should appear in both hands")

func test_deck_reset_restores_54() -> void:
	var d := Deck.new()
	d.deal(17)
	assert_eq(d.size(), 37)
	d.reset()
	assert_eq(d.size(), 54, "Reset should restore 54 cards")

# ---- Hand tests ----

func test_hand_starts_empty() -> void:
	var h := Hand.new()
	assert_eq(h.size(), 0)
	assert_true(h.is_empty())

func test_hand_add_card() -> void:
	var h := Hand.new()
	var c := Card.new("hearts", 7)
	h.add_card(c)
	assert_eq(h.size(), 1)
	assert_false(h.is_empty())

func test_hand_remove_card() -> void:
	var h := Hand.new()
	var c := Card.new("hearts", 7)
	h.add_card(c)
	var removed := h.remove_card(c)
	assert_true(removed)
	assert_eq(h.size(), 0)

func test_hand_remove_nonexistent_returns_false() -> void:
	var h := Hand.new()
	var c := Card.new("hearts", 7)
	var removed := h.remove_card(c)
	assert_false(removed, "Removing nonexistent card should return false")

func test_hand_add_cards_bulk() -> void:
	var d := Deck.new()
	var dealt := d.deal(17)
	var h := Hand.new()
	h.add_cards(dealt)
	assert_eq(h.size(), 17)

func test_hand_get_sorted_ascending() -> void:
	var h := Hand.new()
	h.add_card(Card.new("hearts", 10))
	h.add_card(Card.new("spades", 3))
	h.add_card(Card.new("clubs", 7))
	var sorted := h.get_sorted()
	assert_eq(sorted[0].number, 3)
	assert_eq(sorted[1].number, 7)
	assert_eq(sorted[2].number, 10)

func test_hand_sort_by_number() -> void:
	var h := Hand.new()
	h.add_card(Card.new("spades", 9))
	h.add_card(Card.new("hearts", 3))
	h.add_card(Card.new("clubs", 15))
	h.sort_by_number()
	assert_eq(h.cards[0].number, 3)
	assert_eq(h.cards[1].number, 9)
	assert_eq(h.cards[2].number, 15)

func test_deck_shuffle_with_seed_deterministic() -> void:
	var d1 := Deck.new()
	var d2 := Deck.new()
	var rng1 := RandomNumberGenerator.new()
	var rng2 := RandomNumberGenerator.new()
	rng1.seed = 42
	rng2.seed = 42
	d1.shuffle_deck(rng1)
	d2.shuffle_deck(rng2)
	for i in range(54):
		assert_eq(d1.cards[i].number, d2.cards[i].number)
		assert_eq(d1.cards[i].suit, d2.cards[i].suit)
