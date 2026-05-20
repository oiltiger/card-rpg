# combat/character_data.gd
class_name CharacterData
extends RefCounted

var character_name: String = ""
var ultimate_description: String = ""
var ultimate_callable: Callable = Callable()  # null/empty in Phase 1

func _init(p_name: String = "", p_desc: String = "", p_callable: Callable = Callable()) -> void:
	character_name = p_name
	ultimate_description = p_desc
	ultimate_callable = p_callable
