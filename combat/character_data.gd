# combat/character_data.gd
class_name CharacterData
extends RefCounted

var character_name: String = ""
var id: String = ""
var display_name: String = ""
var description: String = ""
var max_hp: int = 150
var passive_id: String = ""
var ultimate_id: String = ""
var ultimate_description: String = ""
var ultimate_callable: Callable = Callable()  # null/empty in Phase 1

func _init(
	p_name: String = "",
	p_desc: String = "",
	p_callable: Callable = Callable(),
	p_id: String = "",
	p_max_hp: int = 150,
	p_passive_id: String = "",
	p_ultimate_id: String = ""
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

static func create(character_id: String) -> CharacterData:
	match character_id:
		"warrior":
			return CharacterData.new("战士", "大招：造成 40 点伤害。被动：炸弹和四带二 +10 伤害。", Callable(), "warrior", 250, "warrior_damage", "warrior_strike")
		"trickster":
			return CharacterData.new("术士", "大招：选择一张普通手牌变为 wild。被动：含 wild 出牌额外 +1 虚点。", Callable(), "trickster", 150, "wild_virtual", "make_wild")
		"monk":
			return CharacterData.new("武僧", "大招：下一次对手造成的伤害全部反弹。被动：每第三次有效出牌 +1 实点。", Callable(), "monk", 200, "monk_combo", "reflect_next")
	return CharacterData.new("战士", "大招：造成 40 点伤害。被动：炸弹和四带二 +10 伤害。", Callable(), "warrior", 250, "warrior_damage", "warrior_strike")

static func all_player_characters() -> Array[CharacterData]:
	return [create("warrior"), create("trickster"), create("monk")]
