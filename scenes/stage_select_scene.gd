# scenes/stage_select_scene.gd
class_name StageSelectScene
extends Control

@onready var stage_row: HBoxContainer = $Root/StageRow
@onready var selected_label: Label = $Root/SelectedLabel

const STAGES := [
	{"id": "normal", "name": "普通敌人", "difficulty": "easy", "hp": 200},
	{"id": "elite", "name": "精英敌人", "difficulty": "normal", "hp": 300},
	{"id": "boss_test", "name": "强敌测试", "difficulty": "hard", "hp": 400},
]

func _ready() -> void:
	var data := CharacterData.create(RunState.selected_character_id)
	selected_label.text = "当前角色：%s  HP %d" % [data.display_name, data.max_hp]
	_render_stages()

func _render_stages() -> void:
	for child in stage_row.get_children():
		child.queue_free()
	for stage in STAGES:
		var panel := VBoxContainer.new()
		panel.custom_minimum_size = Vector2(310, 220)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := Label.new()
		title.text = "%s" % stage["name"]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(title)
		var desc := Label.new()
		desc.text = "AI: %s\nHP: %d" % [stage["difficulty"], stage["hp"]]
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		panel.add_child(desc)
		var button := Button.new()
		button.text = "开始战斗"
		button.pressed.connect(func() -> void: _select_stage(stage["id"], stage["difficulty"]))
		panel.add_child(button)
		stage_row.add_child(panel)

func _select_stage(stage_id: String, difficulty: String) -> void:
	RunState.select_stage(stage_id, difficulty)
	get_tree().change_scene_to_file("res://scenes/BattleScene.tscn")

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/CharacterSelectScene.tscn")
