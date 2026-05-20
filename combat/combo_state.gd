# combat/combo_state.gd
class_name ComboState
extends RefCounted

var active: bool = false
var prev_hand_type: int = -1  # -1 = uninitialized; DoudizhuRules.HandType.INVALID == 0
var prev_card_count: int = 0

func reset() -> void:
	active = false
	prev_hand_type = -1
	prev_card_count = 0

# Check whether the current play continues the combo.
# Returns true if combo continues (or starts), false if broken.
# Updates prev_hand_type / prev_card_count on continuation.
func check_combo(current_type: int, current_count: int, has_wild: bool) -> bool:
	if not active:
		active = true
		prev_hand_type = current_type
		prev_card_count = current_count
		return true

	# Same type continues combo
	if current_type == prev_hand_type:
		prev_hand_type = current_type
		prev_card_count = current_count
		return true
	# Ascending count by exactly 1 continues
	if current_count == prev_card_count + 1:
		prev_hand_type = current_type
		prev_card_count = current_count
		return true
	# Wild card forces continuation
	if has_wild:
		prev_hand_type = current_type
		prev_card_count = current_count
		return true

	# Combo broken
	return false
