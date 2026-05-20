# scenes/battle_scene.gd  — full implementation (T11)
class_name BattleSceneNode
extends Node2D

@onready var main_layout: VBoxContainer = $MainLayout
@onready var fighter_area: FighterArea = $MainLayout/FighterArea
@onready var hand_area: HandArea = $MainLayout/HandArea

var battle_state: BattleState = null
var player: Combatant = null
var ai: Combatant = null
var rounds_played: int = 0
var total_damage_dealt: int = 0
var max_combo_count: int = 0
var _current_combo_count: int = 0

func _ready() -> void:
	hand_area.play_pressed.connect(_on_play_pressed)
	hand_area.pass_pressed.connect(_on_pass_pressed)
	hand_area.ultimate_requested.connect(_on_ultimate_requested)
	hand_area.restart_requested.connect(_start_new_battle)
	_start_new_battle()

func _start_new_battle() -> void:
	player = Combatant.new(CharacterData.new("玩家", "斩!", Callable()))
	ai = AICombatant.new()
	ai.character_data = CharacterData.new("AI", "", Callable())
	battle_state = BattleState.new()
	battle_state.start_battle(player, ai)
	rounds_played = 0
	total_damage_dealt = 0
	max_combo_count = 0
	_current_combo_count = 0
	hand_area.hide_restart_button()
	hand_area.clear_play_zone()
	hand_area.set_last_play_text("等待出牌...")
	hand_area.render_hand(player.hand.get_cards())
	_refresh_ui()
	if battle_state.current_attacker == ai:
		_ai_turn()

func _refresh_ui() -> void:
	fighter_area.update_hp(player.hp, player.max_hp, ai.hp, ai.max_hp, ai.hand.size())
	fighter_area.update_round(battle_state.round_number)
	fighter_area.update_energy(
		player.energy_bar.virtual_points, player.energy_bar.real_points, player.energy_bar.energy_points,
		ai.energy_bar.virtual_points, ai.energy_bar.real_points, ai.energy_bar.energy_points
	)
	hand_area.set_ultimate_enabled(player.energy_points > 0)
	var is_player_turn := battle_state.current_attacker == player and battle_state.turn_phase != BattleState.TurnPhase.BATTLE_OVER
	hand_area.set_buttons_enabled(is_player_turn, is_player_turn and not battle_state.last_play.is_empty())

func _on_play_pressed() -> void:
	if battle_state.current_attacker != player:
		return
	var selected := hand_area.get_selected_cards()
	if selected.is_empty():
		hand_area.set_last_play_text("请先选择卡牌")
		return
	var result := battle_state.process_play(player, selected)
	if not result.valid:
		hand_area.set_last_play_text("出牌无效")
		return
	total_damage_dealt += result.damage
	if result.combo_continued:
		_current_combo_count += 1
		max_combo_count = max(max_combo_count, _current_combo_count)
	else:
		_current_combo_count = 1
	hand_area.show_played_cards("player", selected, CardToAction.action_name(result.hand_type))
	if result["penalty_damage"] > 0:
		hand_area.clear_play_zone()
		hand_area.set_last_play_text("手牌打完！AI 受到 %d 惩罚伤害，重新发牌！" % result["penalty_damage"])
	else:
		hand_area.set_last_play_text("我方: %s (%d 伤害)" % [CardToAction.action_name(result.hand_type), result.damage])
	hand_area.render_hand(player.hand.get_cards())
	_refresh_ui()
	if result.get("battle_over", false):
		_show_battle_over()
		return
	await get_tree().create_timer(0.5).timeout
	_ai_turn()

func _on_pass_pressed() -> void:
	if battle_state.current_attacker != player:
		return
	if battle_state.last_play.is_empty():
		return
	var result := battle_state.process_pass(player)
	hand_area.clear_play_zone()
	hand_area.set_last_play_text("我方: 过牌 (受到 %d 伤害)" % result.damage_taken)
	_current_combo_count = 0
	_refresh_ui()
	if result.battle_over:
		_show_battle_over()
		return
	await get_tree().create_timer(0.5).timeout
	_ai_turn()

func _ai_turn() -> void:
	if battle_state.turn_phase == BattleState.TurnPhase.BATTLE_OVER:
		return
	while battle_state.current_attacker == ai:
		var choice := ai.choose_card(battle_state)
		if choice.action == "pass":
			var result := battle_state.process_pass(ai)
			hand_area.clear_play_zone()
			hand_area.set_last_play_text("AI: 过牌 (受到 %d 伤害)" % result.damage_taken)
			total_damage_dealt += result.damage_taken
			_refresh_ui()
			if result.battle_over:
				_show_battle_over()
				return
		else:
			var result := battle_state.process_play(ai, choice.cards)
			if not result.valid:
				battle_state.process_pass(ai)
				break
			hand_area.show_played_cards("ai", choice.cards, CardToAction.action_name(result.hand_type))
			if result["penalty_damage"] > 0:
				hand_area.clear_play_zone()
				hand_area.set_last_play_text("AI 手牌打完！我方受到 %d 惩罚伤害，重新发牌！" % result["penalty_damage"])
				hand_area.render_hand(player.hand.get_cards())
				_refresh_ui()
				if result.get("battle_over", false):
					_show_battle_over()
					return
			else:
				hand_area.set_last_play_text("AI: %s (%d 伤害)" % [CardToAction.action_name(result.hand_type), result.damage])
				_refresh_ui()
		await get_tree().create_timer(0.7).timeout
	_refresh_ui()

func _on_ultimate_requested() -> void:
	if battle_state == null or player == null:
		return
	var ok := player.use_ultimate(ai)
	if ok:
		fighter_area.show_skill_label("技能释放！20 伤害")
		_refresh_ui()
		if ai.is_dead():
			battle_state.turn_phase = BattleState.TurnPhase.BATTLE_OVER
			_show_battle_over()

func _show_battle_over() -> void:
	var winner := battle_state.get_winner()
	var who := "我方胜利" if winner == player else "AI胜利"
	hand_area.set_last_play_text("%s | 回合:%d 总伤害:%d 最大连击:%d" %
		[who, battle_state.round_number, total_damage_dealt, max_combo_count])
	hand_area.set_buttons_enabled(false, false)
	hand_area.set_ultimate_enabled(false)
	hand_area.show_restart_button()
