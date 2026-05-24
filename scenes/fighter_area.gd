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

func update_resources(
	p_combo: int,
	p_max_combo: int,
	p_mana: int,
	p_max_mana: int,
	e_combo: int,
	e_max_combo: int,
	e_mana: int,
	e_max_mana: int
) -> void:
	player_energy_label.text = "连击: %d/%d  蓝: %d/%d" % [p_combo, p_max_combo, p_mana, p_max_mana]
	enemy_energy_label.text = "连击: %d/%d  蓝: %d/%d" % [e_combo, e_max_combo, e_mana, e_max_mana]

func show_skill_label(text: String) -> void:
	skill_label.text = text
	skill_label.visible = true
	await get_tree().create_timer(2.0).timeout
	skill_label.visible = false
