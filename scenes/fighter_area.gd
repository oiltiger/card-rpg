# scenes/fighter_area.gd
class_name FighterArea
extends Control

@onready var player_fighter: ColorRect = $PlayerFighter
@onready var enemy_fighter: ColorRect = $EnemyFighter
@onready var skill_label: Label = $SkillLabel
@onready var info_bar: HBoxContainer = $InfoBar
@onready var player_hp_label: Label = $InfoBar/PlayerHPLabel
@onready var round_label: Label = $InfoBar/RoundLabel
@onready var enemy_hp_label: Label = $InfoBar/EnemyHPLabel
@onready var player_energy_label: Label = $EnergyRow/PlayerEnergyLabel
@onready var enemy_energy_label: Label = $EnergyRow/EnemyEnergyLabel
@onready var player_name_label: Label = $NameRow/PlayerNameLabel
@onready var enemy_name_label: Label = $NameRow/EnemyNameLabel

func _ready() -> void:
	skill_label.visible = false

func update_hp(player_hp: int, player_max: int, enemy_hp: int, enemy_max: int, ai_cards: int = 0) -> void:
	player_hp_label.text = "我: %d/%d" % [player_hp, player_max]
	enemy_hp_label.text = "敌: %d/%d [%d张]" % [enemy_hp, enemy_max, ai_cards]

func update_round(n: int) -> void:
	round_label.text = "第 %d 回合" % n

func update_names(player_name: String, ai_difficulty: String) -> void:
	player_name_label.text = player_name
	enemy_name_label.text = "AI %s" % ai_difficulty

func update_energy(p_virtual: int, p_real: int, p_energy: int, e_virtual: int, e_real: int, e_energy: int) -> void:
	player_energy_label.text = "蓄气: %d/10  积: %s" % [p_real + p_virtual, _to_chinese(p_energy)]
	enemy_energy_label.text = "蓄气: %d/10  积: %s" % [e_real + e_virtual, _to_chinese(e_energy)]

static func _to_chinese(n: int) -> String:
	const NUMS := ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
	if n <= 0:
		return "无"
	var s := ""
	for i in range(n):
		s += NUMS[i % 10]
	return s

func show_skill_label(text: String) -> void:
	skill_label.text = text
	skill_label.visible = true
	await get_tree().create_timer(2.0).timeout
	skill_label.visible = false
