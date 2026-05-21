# run_state.gd
extends Node

var selected_character_id: String = "warrior"
var selected_stage_id: String = "easy"
var selected_ai_difficulty: String = "easy"
var last_battle_won: bool = false

func select_character(character_id: String) -> void:
	selected_character_id = character_id

func select_stage(stage_id: String, ai_difficulty: String) -> void:
	selected_stage_id = stage_id
	selected_ai_difficulty = ai_difficulty

func reset_run() -> void:
	selected_character_id = "warrior"
	selected_stage_id = "easy"
	selected_ai_difficulty = "easy"
	last_battle_won = false
