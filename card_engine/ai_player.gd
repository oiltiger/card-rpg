# card_engine/ai_player.gd
class_name AICombatant
extends Combatant

# Simple AI:
# - Must respond (last_play not empty AND not from self): find smallest valid counter
# - Free (last_play empty OR from self): if opponent.hand <= 5 → strongest, else → smallest single

func choose_card(battle_state) -> Dictionary:
	var last: PlayedHand = battle_state.last_play
	var opponent: Combatant = battle_state.player if battle_state.enemy == self else battle_state.enemy

	# Case A: must respond
	if last != null and not last.is_empty() and last.combatant_ref != self:
		var counter := _find_smallest_counter(last.cards)
		if counter.is_empty():
			return {"action": "pass", "cards": []}
		return {"action": "play", "cards": counter}

	# Case B: free to play (opening or own last_play)
	if opponent.hand.size() <= 5:
		var strong := _find_strongest_play()
		if not strong.is_empty():
			return {"action": "play", "cards": strong}
	# Default: play smallest single
	var single := _find_smallest_single()
	if single.is_empty():
		return {"action": "pass", "cards": []}
	return {"action": "play", "cards": single}

func _find_smallest_single() -> Array[Card]:
	if hand.size() == 0:
		return []
	var sorted := hand.get_cards()
	sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)
	return [sorted[0]] as Array[Card]

# Search for smallest hand that beats target.
func _to_card_array(arr) -> Array[Card]:
	var result: Array[Card] = []
	for c in arr:
		result.append(c as Card)
	return result

func _find_smallest_counter(target: Array[Card]) -> Array[Card]:
	var target_type := DoudizhuRules.identify_hand(target)
	var cards := hand.get_cards()
	cards.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)

	# Try same-type counters by enumerating relevant subsets.
	var same_type := _enumerate_same_type(cards, target_type, target.size())
	for combo in same_type:
		var combo_cards := _to_card_array(combo)
		if DoudizhuRules.can_beat(combo_cards, target):
			return combo_cards

	# Try bombs
	var bombs := _enumerate_bombs(cards)
	for b in bombs:
		var b_cards := _to_card_array(b)
		if DoudizhuRules.can_beat(b_cards, target):
			return b_cards

	# Try royal bomb
	var rb := _find_royal_bomb(cards)
	if not rb.is_empty():
		return rb

	return []

func _find_strongest_play() -> Array[Card]:
	var cards := hand.get_cards()
	var rb := _find_royal_bomb(cards)
	if not rb.is_empty():
		return rb
	var bombs := _enumerate_bombs(cards)
	if bombs.size() > 0:
		bombs.sort_custom(func(a: Array, b: Array) -> bool: return a[0].number > b[0].number)
		return _to_card_array(bombs[0])
	# Triple_pair
	var triples := _find_triples(cards)
	var pairs := _find_pairs(cards)
	if triples.size() > 0 and pairs.size() > 0:
		var tp: Array[Card] = []
		for c in triples[0]:
			tp.append(c as Card)
		var pair := []
		for p in pairs:
			if p[0].number != triples[0][0].number:
				pair = p
				break
		if pair.size() > 0:
			for c in pair:
				tp.append(c as Card)
			return tp
	if triples.size() > 0:
		return _to_card_array(triples[0])
	if pairs.size() > 0:
		return _to_card_array(pairs[0])
	return _find_smallest_single()

# ---------- Combo enumeration helpers ----------

func _find_pairs(cards: Array[Card]) -> Array:
	var counts := {}
	for c in cards:
		if c.is_wild():
			continue
		counts[c.number] = counts.get(c.number, []) + [c]
	var result := []
	var nums := counts.keys()
	nums.sort()
	for n in nums:
		var arr = counts[n]
		if arr.size() >= 2:
			result.append([arr[0], arr[1]])
	return result

func _find_triples(cards: Array[Card]) -> Array:
	var counts := {}
	for c in cards:
		if c.is_wild():
			continue
		counts[c.number] = counts.get(c.number, []) + [c]
	var result := []
	var nums := counts.keys()
	nums.sort()
	for n in nums:
		var arr = counts[n]
		if arr.size() >= 3:
			result.append([arr[0], arr[1], arr[2]])
	return result

func _enumerate_bombs(cards: Array[Card]) -> Array:
	var counts := {}
	for c in cards:
		if c.is_wild():
			continue
		counts[c.number] = counts.get(c.number, []) + [c]
	var result := []
	var nums := counts.keys()
	nums.sort()
	for n in nums:
		var arr = counts[n]
		if arr.size() >= 4:
			result.append([arr[0], arr[1], arr[2], arr[3]])
	return result

func _find_royal_bomb(cards: Array[Card]) -> Array[Card]:
	var small: Card = null
	var big: Card = null
	for c in cards:
		if c.suit == "joker" and c.number == 16:
			small = c
		elif c.suit == "joker" and c.number == 17:
			big = c
	if small != null and big != null:
		return [small, big] as Array[Card]
	return []

# Enumerate same-type plays of given target_size.
func _enumerate_same_type(cards: Array[Card], target_type: int, target_size: int) -> Array:
	match target_type:
		DoudizhuRules.HandType.SINGLE:
			var result := []
			var sorted := cards.duplicate()
			sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)
			for c in sorted:
				if c.suit == "joker":
					continue
				result.append([c])
			return result
		DoudizhuRules.HandType.PAIR:
			return _find_pairs(cards)
		DoudizhuRules.HandType.TRIPLE:
			return _find_triples(cards)
		DoudizhuRules.HandType.TRIPLE_ONE:
			var result := []
			var triples := _find_triples(cards)
			for t in triples:
				for c in cards:
					if c.number != t[0].number and not c.is_wild():
						var combo = t.duplicate()
						combo.append(c)
						result.append(combo)
						break
			return result
		DoudizhuRules.HandType.TRIPLE_PAIR:
			var result := []
			var triples := _find_triples(cards)
			var pairs := _find_pairs(cards)
			for t in triples:
				for p in pairs:
					if p[0].number != t[0].number:
						var combo = t.duplicate()
						combo.append_array(p)
						result.append(combo)
						break
			return result
		DoudizhuRules.HandType.BOMB:
			return _enumerate_bombs(cards)
	# For STRAIGHT/CONSECUTIVE_PAIRS/FOUR_TWO: Phase 1 AI does not enumerate
	return []
