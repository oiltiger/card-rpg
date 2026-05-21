# scenes/character_select_scene.gd
class_name CharacterSelectScene
extends Control

@onready var card_row: HBoxContainer = $Root/CardRow

func _ready() -> void:
	_render_characters()

func _render_characters() -> void:
	for child in card_row.get_children():
		child.queue_free()
	for data in CharacterData.all_player_characters():
		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(330, 280)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = "%s  HP %d" % [data.display_name, data.max_hp]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(title)
		var desc := Label.new()
		desc.text = data.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(0, 150)
		panel.add_child(desc)
		var button := Button.new()
		button.text = "选择"
		button.pressed.connect(func() -> void: _select_character(data.id))
		panel.add_child(button)
		card_row.add_child(panel)

func _select_character(character_id: String) -> void:
	RunState.select_character(character_id)
	get_tree().change_scene_to_file("res://scenes/StageSelectScene.tscn")
