# combat/combo_state.gd
class_name ComboState
extends RefCounted

var active: bool = false
var prev_hand_type: int = -1  # -1 = uninitialized; DoudizhuRules.HandType.INVALID == 0
var prev_card_count: int = 0
var chain_count: int = 0

func reset() -> void:
	active = false
	prev_hand_type = -1
	prev_card_count = 0
	chain_count = 0

# Check whether the current play continues the combo.
# First valid play only starts the chain and returns false.
# Returns true only from the second linked play onward.
func check_combo(current_type: int, current_count: int, has_wild: bool) -> bool:
	if not active:
		active = true
		prev_hand_type = current_type
		prev_card_count = current_count
		chain_count = 1
		return false

	# Same type continues combo
	if current_type == prev_hand_type:
		prev_hand_type = current_type
		prev_card_count = current_count
		chain_count += 1
		return true
	# Ascending count by exactly 1 continues
	if current_count == prev_card_count + 1:
		prev_hand_type = current_type
		prev_card_count = current_count
		chain_count += 1
		return true
	# Wild card forces continuation
	if has_wild:
		prev_hand_type = current_type
		prev_card_count = current_count
		chain_count += 1
		return true

	# Combo broken
	return false
