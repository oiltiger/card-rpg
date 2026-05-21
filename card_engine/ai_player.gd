# card_engine/ai_player.gd
class_name AICombatant
extends Combatant

var difficulty: String = "easy"

func _init(p_difficulty: String = "easy") -> void:
	difficulty = p_difficulty
	super()
	match difficulty:
		"normal":
			max_hp = 300
		"hard":
			max_hp = 400
		_:
			max_hp = 200
	hp = max_hp

func choose_card(battle_state) -> Dictionary:
	match difficulty:
		"normal":
			return _choose_normal(battle_state)
		"hard":
			return _choose_hard(battle_state)
	return _choose_easy(battle_state)

func _choose_easy(battle_state) -> Dictionary:
	var last: PlayedHand = battle_state.last_play
	var opponent: Combatant = battle_state.player if battle_state.enemy == self else battle_state.enemy
	if last != null and not last.is_empty() and last.combatant_ref != self:
		var counter := _find_smallest_counter(last.cards)
		if counter.is_empty():
			return {"action": "pass", "cards": []}
		return {"action": "play", "cards": counter}
	if opponent.hand.size() <= 5:
		var strong := _find_strongest_play()
		if not strong.is_empty():
			return {"action": "play", "cards": strong}
	var single := _find_smallest_single()
	if single.is_empty():
		return {"action": "pass", "cards": []}
	return {"action": "play", "cards": single}

func _choose_normal(battle_state) -> Dictionary:
	var last: PlayedHand = battle_state.last_play
	if last != null and not last.is_empty() and last.combatant_ref != self:
		var counter := _find_smallest_counter(last.cards, false)
		if counter.is_empty():
			counter = _find_smallest_counter(last.cards, true)
		if counter.is_empty():
			return {"action": "pass", "cards": []}
		return {"action": "play", "cards": counter}
	var long_play := _find_best_long_play(false)
	if not long_play.is_empty():
		return {"action": "play", "cards": long_play}
	return _choose_easy(battle_state)

func _choose_hard(battle_state) -> Dictionary:
	var opponent: Combatant = battle_state.player if battle_state.enemy == self else battle_state.enemy
	var last: PlayedHand = battle_state.last_play
	if last != null and not last.is_empty() and last.combatant_ref != self:
		var allow_power := opponent.hand.size() <= 3 or hp <= 120
		var counter := _find_smallest_counter(last.cards, allow_power)
		if counter.is_empty() and not allow_power:
			counter = _find_smallest_counter(last.cards, true)
		if counter.is_empty():
			return {"action": "pass", "cards": []}
		return {"action": "play", "cards": counter}
	var long_play := _find_best_long_play(true)
	if not long_play.is_empty():
		return {"action": "play", "cards": long_play}
	return _choose_easy(battle_state)

func should_use_ultimate(battle_state) -> bool:
	if difficulty == "easy" or energy_points <= 0:
		return false
	var opponent: Combatant = battle_state.player if battle_state.enemy == self else battle_state.enemy
	if difficulty == "hard":
		return opponent.hp <= 40 or hp <= 100 or opponent.hand.size() <= 3
	return opponent.hp <= 40 or hp <= 80

func _find_smallest_single() -> Array[Card]:
	if hand.size() == 0:
		return []
	var sorted := hand.get_cards()
	sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)
	return [sorted[0]] as Array[Card]

func _to_card_array(arr) -> Array[Card]:
	var result: Array[Card] = []
	for c in arr:
		result.append(c as Card)
	return result

func _find_smallest_counter(target: Array[Card], allow_power_cards: bool = true) -> Array[Card]:
	var target_type := DoudizhuRules.identify_hand(target)
	var cards := hand.get_cards()
	cards.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)

	var same_type := _enumerate_same_type(cards, target_type, target.size())
	same_type.sort_custom(func(a: Array, b: Array) -> bool:
		var a_cards := _to_card_array(a)
		var b_cards := _to_card_array(b)
		return DoudizhuRules._anchor(a_cards, target_type) < DoudizhuRules._anchor(b_cards, target_type)
	)
	for combo in same_type:
		var combo_cards := _to_card_array(combo)
		if DoudizhuRules.can_beat(combo_cards, target):
			return combo_cards

	if allow_power_cards:
		var bombs := _enumerate_bombs(cards)
		for b in bombs:
			var b_cards := _to_card_array(b)
			if DoudizhuRules.can_beat(b_cards, target):
				return b_cards
		var rb := _find_royal_bomb(cards)
		if not rb.is_empty():
			return rb
	return []

func _find_best_long_play(include_power_cards: bool) -> Array[Card]:
	var candidates := _enumerate_opening_long_plays(hand.get_cards(), include_power_cards)
	if candidates.is_empty():
		return []
	candidates.sort_custom(func(a: Array, b: Array) -> bool:
		return _opening_score(a) > _opening_score(b)
	)
	return _to_card_array(candidates[0])

func _opening_score(combo: Array) -> int:
	var cards := _to_card_array(combo)
	var type := DoudizhuRules.identify_hand(cards)
	var score := cards.size() * 100 + CardToAction.compute_damage(type, cards.size())
	if type == DoudizhuRules.HandType.BOMB or type == DoudizhuRules.HandType.ROYAL_BOMB:
		score -= 80
	return score - DoudizhuRules._anchor(cards, type)

func _find_strongest_play() -> Array[Card]:
	var cards := hand.get_cards()
	var rb := _find_royal_bomb(cards)
	if not rb.is_empty():
		return rb
	var bombs := _enumerate_bombs(cards)
	if bombs.size() > 0:
		bombs.sort_custom(func(a: Array, b: Array) -> bool: return a[0].number > b[0].number)
		return _to_card_array(bombs[0])
	var long_play := _find_best_long_play(false)
	if not long_play.is_empty():
		return long_play
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

func _number_groups(cards: Array[Card]) -> Dictionary:
	var groups := {}
	for c in cards:
		if c.is_wild():
			continue
		groups[c.number] = groups.get(c.number, []) + [c]
	return groups

func _find_pairs(cards: Array[Card]) -> Array:
	var groups := _number_groups(cards)
	var result := []
	var nums := groups.keys()
	nums.sort()
	for n in nums:
		var arr = groups[n]
		if arr.size() >= 2:
			result.append([arr[0], arr[1]])
	return result

func _find_triples(cards: Array[Card]) -> Array:
	var groups := _number_groups(cards)
	var result := []
	var nums := groups.keys()
	nums.sort()
	for n in nums:
		var arr = groups[n]
		if arr.size() >= 3:
			result.append([arr[0], arr[1], arr[2]])
	return result

func _enumerate_bombs(cards: Array[Card]) -> Array:
	var groups := _number_groups(cards)
	var result := []
	var nums := groups.keys()
	nums.sort()
	for n in nums:
		var arr = groups[n]
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

func _enumerate_same_type(cards: Array[Card], target_type: int, target_size: int) -> Array:
	match target_type:
		DoudizhuRules.HandType.SINGLE:
			var result := []
			var sorted := cards.duplicate()
			sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)
			for c in sorted:
				result.append([c])
			return result
		DoudizhuRules.HandType.PAIR:
			return _find_pairs(cards)
		DoudizhuRules.HandType.TRIPLE:
			return _find_triples(cards)
		DoudizhuRules.HandType.TRIPLE_ONE:
			return _enumerate_triple_one(cards)
		DoudizhuRules.HandType.TRIPLE_PAIR:
			return _enumerate_triple_pair(cards)
		DoudizhuRules.HandType.STRAIGHT:
			return _enumerate_straights(cards, target_size)
		DoudizhuRules.HandType.CONSECUTIVE_PAIRS:
			return _enumerate_consecutive_pairs(cards, target_size / 2)
		DoudizhuRules.HandType.AIRPLANE_SINGLE:
			return _enumerate_airplane_single(cards, target_size / 4)
		DoudizhuRules.HandType.AIRPLANE_PAIR:
			return _enumerate_airplane_pair(cards, target_size / 5)
		DoudizhuRules.HandType.BOMB:
			return _enumerate_bombs(cards)
		DoudizhuRules.HandType.FOUR_TWO:
			return _enumerate_four_two(cards)
	return []

func _enumerate_opening_long_plays(cards: Array[Card], include_power_cards: bool) -> Array:
	var result := []
	for combo in _enumerate_airplane_pair(cards):
		result.append(combo)
	for combo in _enumerate_airplane_single(cards):
		result.append(combo)
	for combo in _enumerate_straights(cards):
		result.append(combo)
	for combo in _enumerate_consecutive_pairs(cards):
		result.append(combo)
	for combo in _enumerate_triple_pair(cards):
		result.append(combo)
	for combo in _enumerate_triple_one(cards):
		result.append(combo)
	for combo in _enumerate_four_two(cards):
		result.append(combo)
	if include_power_cards:
		for combo in _enumerate_bombs(cards):
			result.append(combo)
		var rb := _find_royal_bomb(cards)
		if not rb.is_empty():
			result.append(rb)
	return result

func _enumerate_triple_one(cards: Array[Card]) -> Array:
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

func _enumerate_triple_pair(cards: Array[Card]) -> Array:
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

func _enumerate_straights(cards: Array[Card], exact_size: int = 0) -> Array:
	var groups := _number_groups(cards)
	var nums := groups.keys()
	nums.sort()
	var min_len := exact_size if exact_size > 0 else 5
	var max_len := exact_size if exact_size > 0 else nums.size()
	return _enumerate_runs(groups, nums, min_len, max_len, 1)

func _enumerate_consecutive_pairs(cards: Array[Card], exact_pair_count: int = 0) -> Array:
	var groups := _number_groups(cards)
	var nums := []
	for n in groups.keys():
		if groups[n].size() >= 2:
			nums.append(n)
	nums.sort()
	var min_len := exact_pair_count if exact_pair_count > 0 else 3
	var max_len := exact_pair_count if exact_pair_count > 0 else nums.size()
	return _enumerate_runs(groups, nums, min_len, max_len, 2)

func _enumerate_runs(groups: Dictionary, nums: Array, min_len: int, max_len: int, copies: int) -> Array:
	var result := []
	for start in range(0, nums.size()):
		var seq := []
		for i in range(start, nums.size()):
			var n = nums[i]
			if n >= 15:
				break
			if not seq.is_empty() and n != seq[seq.size() - 1] + 1:
				break
			seq.append(n)
			if seq.size() >= min_len and seq.size() <= max_len:
				var combo := []
				for sn in seq:
					for c in groups[sn].slice(0, copies):
						combo.append(c)
				result.append(combo)
	return result

func _enumerate_airplane_single(cards: Array[Card], exact_triple_count: int = 0) -> Array:
	var result := []
	var groups := _number_groups(cards)
	for triple_nums in _enumerate_triple_runs(groups, exact_triple_count):
		var wings := _first_single_wings(cards, triple_nums, triple_nums.size())
		if wings.size() == triple_nums.size():
			result.append(_cards_for_triples(groups, triple_nums) + wings)
	return result

func _enumerate_airplane_pair(cards: Array[Card], exact_triple_count: int = 0) -> Array:
	var result := []
	var groups := _number_groups(cards)
	for triple_nums in _enumerate_triple_runs(groups, exact_triple_count):
		var wings := _first_pair_wings(groups, triple_nums, triple_nums.size())
		if wings.size() == triple_nums.size() * 2:
			result.append(_cards_for_triples(groups, triple_nums) + wings)
	return result

func _enumerate_triple_runs(groups: Dictionary, exact_triple_count: int = 0) -> Array:
	var nums := []
	for n in groups.keys():
		if n < 15 and groups[n].size() >= 3:
			nums.append(n)
	nums.sort()
	var min_len := exact_triple_count if exact_triple_count > 0 else 2
	var max_len := exact_triple_count if exact_triple_count > 0 else nums.size()
	var result := []
	for start in range(0, nums.size()):
		var seq := []
		for i in range(start, nums.size()):
			var n = nums[i]
			if not seq.is_empty() and n != seq[seq.size() - 1] + 1:
				break
			seq.append(n)
			if seq.size() >= min_len and seq.size() <= max_len:
				result.append(seq.duplicate())
	return result

func _cards_for_triples(groups: Dictionary, triple_nums: Array) -> Array:
	var result := []
	for n in triple_nums:
		result.append_array(groups[n].slice(0, 3))
	return result

func _first_single_wings(cards: Array[Card], triple_nums: Array, wing_count: int) -> Array:
	var result := []
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a: Card, b: Card) -> bool: return a.number < b.number)
	for c in sorted:
		if c.is_wild() or c.number in triple_nums:
			continue
		result.append(c)
		if result.size() == wing_count:
			break
	return result

func _first_pair_wings(groups: Dictionary, triple_nums: Array, pair_count: int) -> Array:
	var result := []
	var nums := groups.keys()
	nums.sort()
	for n in nums:
		if n in triple_nums or groups[n].size() < 2:
			continue
		result.append_array(groups[n].slice(0, 2))
		if result.size() == pair_count * 2:
			break
	return result

func _enumerate_four_two(cards: Array[Card]) -> Array:
	var result := []
	var bombs := _enumerate_bombs(cards)
	for b in bombs:
		var kickers := []
		for c in cards:
			if not c in b and not c.is_wild():
				kickers.append(c)
			if kickers.size() == 2:
				break
		if kickers.size() == 2:
			var combo = b.duplicate()
			combo.append_array(kickers)
			result.append(combo)
	return result
