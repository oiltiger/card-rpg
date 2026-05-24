# combat/character_data.gd
class_name CharacterData
extends RefCounted

var character_name: String = ""
var id: String = ""
var display_name: String = ""
var description: String = ""
var max_hp: int = 150
var max_combo_points: int = 0
var max_mana: int = 0
var character_skill_mana_cost: int = 0
var passive_id: String = ""
var ultimate_id: String = ""
var ultimate_description: String = ""
var ultimate_callable: Callable = Callable()

func _init(
	p_name: String = "",
	p_desc: String = "",
	p_callable: Callable = Callable(),
	p_id: String = "",
	p_max_hp: int = 150,
	p_passive_id: String = "",
	p_ultimate_id: String = "",
	p_max_combo_points: int = 0,
	p_max_mana: int = 0,
	p_skill_mana_cost: int = 0
) -> void:
	character_name = p_name
	display_name = p_name
	ultimate_description = p_desc
	ultimate_callable = p_callable
	id = p_id
	description = p_desc
	max_hp = p_max_hp
	passive_id = p_passive_id
	ultimate_id = p_ultimate_id
	max_combo_points = p_max_combo_points
	max_mana = p_max_mana
	character_skill_mana_cost = p_skill_mana_cost

static func create(character_id: String) -> CharacterData:
	match character_id:
		"warrior":
			return CharacterData.new("战士", "职业技：消耗 3 蓝，造成 40 点伤害。被动：炸弹、同花顺和四带二 +10 伤害。", Callable(), "warrior", 250, "warrior_damage", "warrior_strike", 3, 3, 3)
		"mage", "trickster":
			return CharacterData.new("法师", "职业技：消耗 4 蓝，选择一张普通手牌变为 wild。被动：含 wild 出牌额外 +1 连击点。", Callable(), "mage", 150, "wild_combo", "make_wild", 5, 8, 4)
		"monk":
			return CharacterData.new("武僧", "职业技：消耗 4 蓝，下一次对手造成的伤害全部反弹。被动：每第三次有效出牌 +1 连击点。", Callable(), "monk", 200, "monk_combo", "reflect_next", 8, 5, 4)
	return CharacterData.create("warrior")

static func all_player_characters() -> Array[CharacterData]:
	return [create("warrior"), create("mage"), create("monk")]
