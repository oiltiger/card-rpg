# combat/card_to_action.gd
class_name CardToAction
extends RefCounted

const HT = DoudizhuRules.HandType

static func action_name(hand_type: int) -> String:
	match hand_type:
		HT.SINGLE: return "刺击"
		HT.PAIR: return "双击"
		HT.TRIPLE: return "三连"
		HT.TRIPLE_ONE: return "三带一"
		HT.TRIPLE_PAIR: return "三带二"
		HT.STRAIGHT: return "顺子"
		HT.CONSECUTIVE_PAIRS: return "连对"
		HT.AIRPLANE_SINGLE: return "飞机带单"
		HT.AIRPLANE_PAIR: return "飞机带对"
		HT.FOUR_TWO: return "四带二"
		HT.BOMB: return "炸弹"
		HT.ROYAL_BOMB: return "王炸"
	return "无效"

static func compute_damage(hand_type: int, card_count: int) -> int:
	match hand_type:
		HT.INVALID: return 0
		HT.FOUR_TWO: return 70
		HT.BOMB: return 60
		HT.ROYAL_BOMB: return 100
		_: return card_count * 10
