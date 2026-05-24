# card_engine/doudizhu_rules.gd
class_name DoudizhuRules
extends RefCounted

enum HandType {
	INVALID,
	SINGLE,
	PAIR,
	TRIPLE,
	TRIPLE_ONE,
	TRIPLE_PAIR,
	STRAIGHT,
	CONSECUTIVE_PAIRS,
	AIRPLANE_SINGLE,
	AIRPLANE_PAIR,
	FOUR_TWO,
	BOMB,
	STRAIGHT_FLUSH,
	ROYAL_BOMB,
}

# Identify a hand of cards.
# Wild cards can substitute normal numbered cards, but never small/big jokers.
static func identify_hand(cards: Array[Card]) -> int:
	if cards.is_empty():
		return HandType.INVALID
	var n := cards.size()

	# Royal bomb: exactly small + big joker
	if n == 2:
		var has_small := false
		var has_big := false
		for c in cards:
			if c.suit == "joker" and c.number == 16:
				has_small = true
			elif c.suit == "joker" and c.number == 17:
				has_big = true
		if has_small and has_big:
			return HandType.ROYAL_BOMB

	var wilds: Array[Card] = []
	var non_wilds: Array[Card] = []
	for c in cards:
		if c.is_wild():
			wilds.append(c)
		else:
			non_wilds.append(c)

	# Direct match without wild substitution first
	var direct := _identify_without_wild(cards)
	if direct != HandType.INVALID:
		return direct

	var wild_result := _identify_with_wilds(non_wilds, wilds.size())
	if wild_result != HandType.INVALID:
		return wild_result

	return HandType.INVALID

static func _identify_with_wilds(non_wilds: Array[Card], wild_count: int) -> int:
	if wild_count <= 0:
		return HandType.INVALID
	return _try_wild_values(non_wilds, wild_count, [])

static func _try_wild_values(non_wilds: Array[Card], remaining: int, values: Array[int]) -> int:
	if remaining == 0:
		var test_cards := non_wilds.duplicate()
		for value in values:
			test_cards.append(Card.new("spades", value))
		return _identify_without_wild(test_cards)

	var best := HandType.INVALID
	for sub_num in range(3, 16):
		var next_values := values.duplicate()
		next_values.append(sub_num)
		var result := _try_wild_values(non_wilds, remaining - 1, next_values)
		if _hand_type_priority(result) > _hand_type_priority(best):
			best = result
	return best

static func _hand_type_priority(type: int) -> int:
	match type:
		HandType.ROYAL_BOMB: return 10
		HandType.STRAIGHT_FLUSH: return 9
		HandType.BOMB: return 8
		HandType.AIRPLANE_PAIR: return 7
		HandType.AIRPLANE_SINGLE: return 7
		HandType.TRIPLE_PAIR: return 7
		HandType.STRAIGHT: return 6
		HandType.CONSECUTIVE_PAIRS: return 5
		HandType.TRIPLE_ONE: return 4
		HandType.TRIPLE: return 3
		HandType.PAIR: return 2
		HandType.SINGLE: return 1
	return 0

# Pure identification on a card list assumed to contain no wilds.
static func _identify_without_wild(cards: Array[Card]) -> int:
	var n := cards.size()
	if n == 0:
		return HandType.INVALID

	# Check for jokers — only valid as ROYAL_BOMB, handled separately
	for c in cards:
		if c.suit == "joker":
			if n == 2:
				var others := cards.filter(func(x: Card) -> bool: return x != c)
				if others.size() == 1 and others[0].suit == "joker" and others[0].number != c.number:
					return HandType.ROYAL_BOMB
			return HandType.INVALID

	var counts := _count_numbers(cards)
	var numbers := counts.keys()
	numbers.sort()

	if n == 1:
		return HandType.SINGLE
	if n == 2:
		if numbers.size() == 1:
			return HandType.PAIR
		return HandType.INVALID
	if n == 3:
		if numbers.size() == 1:
			return HandType.TRIPLE
		return HandType.INVALID
	if n == 4:
		if numbers.size() == 1:
			return HandType.BOMB
		var has_triple := false
		var has_single := false
		for num in numbers:
			if counts[num] == 3:
				has_triple = true
			elif counts[num] == 1:
				has_single = true
		if has_triple and has_single and numbers.size() == 2:
			return HandType.TRIPLE_ONE
		return HandType.INVALID
	if n == 5:
		var has_t := false
		var has_p := false
		for num in numbers:
			if counts[num] == 3:
				has_t = true
			elif counts[num] == 2:
				has_p = true
		if has_t and has_p and numbers.size() == 2:
			return HandType.TRIPLE_PAIR
		if _is_straight_flush(cards):
			return HandType.STRAIGHT_FLUSH
		if _is_straight(cards):
			return HandType.STRAIGHT
		return HandType.INVALID

	# n >= 6
	if n >= 5 and _is_straight_flush(cards):
		return HandType.STRAIGHT_FLUSH
	if n >= 5 and _is_straight(cards):
		return HandType.STRAIGHT
	if n >= 6 and n % 2 == 0 and _is_consecutive_pairs(cards):
		return HandType.CONSECUTIVE_PAIRS
	if n >= 8 and n % 4 == 0 and _is_airplane_single(cards):
		return HandType.AIRPLANE_SINGLE
	if n >= 10 and n % 5 == 0 and _is_airplane_pair(cards):
		return HandType.AIRPLANE_PAIR
	if n == 6 and _is_four_two(cards):
		return HandType.FOUR_TWO
	return HandType.INVALID

static func _count_numbers(cards: Array[Card]) -> Dictionary:
	var d := {}
	for c in cards:
		d[c.number] = d.get(c.number, 0) + 1
	return d

static func _is_straight(cards: Array[Card]) -> bool:
	if cards.size() < 5:
		return false
	var nums: Array[int] = []
	for c in cards:
		if c.number >= 15:  # no 2s (15) or jokers
			return false
		nums.append(c.number)
	nums.sort()
	for i in range(1, nums.size()):
		if nums[i] != nums[i - 1] + 1:
			return false
	return true

static func _is_consecutive_pairs(cards: Array[Card]) -> bool:
	if cards.size() < 6 or cards.size() % 2 != 0:
		return false
	var counts := _count_numbers(cards)
	var nums := counts.keys()
	nums.sort()
	for num in nums:
		if counts[num] != 2:
			return false
		if num >= 15:  # no 2s
			return false
	for i in range(1, nums.size()):
		if nums[i] != nums[i - 1] + 1:
			return false
	return true

static func _is_straight_flush(cards: Array[Card]) -> bool:
	if not _is_straight(cards):
		return false
	var suit := cards[0].suit
	for c in cards:
		if c.suit != suit:
			return false
	return true

static func _is_four_two(cards: Array[Card]) -> bool:
	if cards.size() != 6:
		return false
	var counts := _count_numbers(cards)
	for num in counts:
		if counts[num] == 4:
			return true
	return false

static func _is_airplane_single(cards: Array[Card]) -> bool:
	var triple_count := cards.size() / 4
	return not _find_consecutive_triple_nums(cards, triple_count).is_empty()

static func _is_airplane_pair(cards: Array[Card]) -> bool:
	var triple_count := cards.size() / 5
	var triple_nums := _find_consecutive_triple_nums(cards, triple_count)
	if triple_nums.is_empty():
		return false
	var counts := _count_numbers(cards)
	var pair_count := 0
	for num in counts:
		if num in triple_nums:
			if counts[num] != 3:
				return false
		elif counts[num] == 2:
			pair_count += 1
		else:
			return false
	return pair_count == triple_count

static func _find_consecutive_triple_nums(cards: Array[Card], triple_count: int) -> Array:
	if triple_count < 2:
		return []
	var counts := _count_numbers(cards)
	var candidates := []
	for num in counts:
		if num < 15 and counts[num] >= 3:
			candidates.append(num)
	candidates.sort()
	for i in range(0, candidates.size() - triple_count + 1):
		var seq := candidates.slice(i, i + triple_count)
		var ok := true
		for j in range(1, seq.size()):
			if seq[j] != seq[j - 1] + 1:
				ok = false
				break
		if ok:
			return seq
	return []

# ---------- Comparison ----------

# Returns true if attacker beats defender. defender is the previous played hand.
static func can_beat(attacker: Array[Card], defender: Array[Card]) -> bool:
	var atk_type := identify_hand(attacker)
	var def_type := identify_hand(defender)
	if atk_type == HandType.INVALID:
		return false
	if def_type == HandType.INVALID:
		# attacker is opening play — any valid hand "beats" empty
		return true

	# Royal bomb beats everything
	if atk_type == HandType.ROYAL_BOMB:
		return def_type != HandType.ROYAL_BOMB
	# Straight flush beats everything except royal bomb and higher straight flush.
	if atk_type == HandType.STRAIGHT_FLUSH:
		if def_type == HandType.ROYAL_BOMB:
			return false
		if def_type == HandType.STRAIGHT_FLUSH:
			if attacker.size() != defender.size():
				return false
			return _anchor(attacker, atk_type) > _anchor(defender, def_type)
		return true
	if def_type == HandType.STRAIGHT_FLUSH:
		return false
	# Bomb beats non-bomb / non-royal
	if atk_type == HandType.BOMB:
		if def_type == HandType.ROYAL_BOMB:
			return false
		if def_type == HandType.BOMB:
			return _anchor(attacker, atk_type) > _anchor(defender, def_type)
		return true
	if def_type == HandType.BOMB or def_type == HandType.ROYAL_BOMB:
		return false
	# Same type required for normal compare
	if atk_type != def_type:
		return false
	# Same type — for STRAIGHT/CONSECUTIVE_PAIRS, must be same length
	if atk_type in [HandType.STRAIGHT, HandType.STRAIGHT_FLUSH, HandType.CONSECUTIVE_PAIRS, HandType.AIRPLANE_SINGLE, HandType.AIRPLANE_PAIR]:
		if attacker.size() != defender.size():
			return false
	return _anchor(attacker, atk_type) > _anchor(defender, def_type)

# Returns the "anchor" number for comparison purposes.
static func _anchor(cards: Array[Card], type: int) -> int:
	if type == HandType.ROYAL_BOMB:
		return 999

	var non_wilds := cards.filter(func(c: Card) -> bool: return not c.is_wild())
	var counts := _count_numbers(non_wilds)

	match type:
		HandType.SINGLE:
			# Joker singles: use actual number (16=小王, 17=大王) so they outrank regular cards
			if non_wilds.is_empty():
				var max_num := 0
				for c in cards:
					max_num = max(c.number, max_num)
				return max_num
			return non_wilds[0].number
		HandType.PAIR, HandType.TRIPLE:
			if non_wilds.is_empty():
				return 0
			return non_wilds[0].number
		HandType.TRIPLE_ONE, HandType.TRIPLE_PAIR:
			for num in counts:
				if counts[num] >= 3:
					return num
			if non_wilds.size() > 0:
				return non_wilds[0].number
			return 0
		HandType.AIRPLANE_SINGLE, HandType.AIRPLANE_PAIR:
			var triple_count := cards.size() / (4 if type == HandType.AIRPLANE_SINGLE else 5)
			var triple_nums := _find_consecutive_triple_nums(non_wilds, triple_count)
			if not triple_nums.is_empty():
				return triple_nums[0]
			return 0
		HandType.STRAIGHT, HandType.STRAIGHT_FLUSH, HandType.CONSECUTIVE_PAIRS:
			var nums: Array[int] = []
			for c in non_wilds:
				nums.append(c.number)
			nums.sort()
			if nums.is_empty():
				return 0
			return nums[0]
		HandType.FOUR_TWO, HandType.BOMB:
			for num in counts:
				if counts[num] >= 4:
					return num
			var best_num := 0
			var best_cnt := 0
			for num in counts:
				if counts[num] > best_cnt:
					best_cnt = counts[num]
					best_num = num
			return best_num
	return 0
