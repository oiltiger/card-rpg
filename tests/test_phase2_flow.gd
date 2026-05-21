extends GutTest

func test_run_state_selects_character_and_stage() -> void:
	RunState.reset_run()
	RunState.select_character("monk")
	RunState.select_stage("elite", "normal")
	assert_eq(RunState.selected_character_id, "monk")
	assert_eq(RunState.selected_stage_id, "elite")
	assert_eq(RunState.selected_ai_difficulty, "normal")

func test_character_catalog_has_three_characters() -> void:
	var characters := CharacterData.all_player_characters()
	assert_eq(characters.size(), 3)
	assert_eq(characters[0].id, "warrior")
	assert_eq(characters[1].id, "trickster")
	assert_eq(characters[2].id, "monk")
