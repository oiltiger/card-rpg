# tests/test_runner.gd
# Documents how to run GUT tests.
# Command line: godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests -gexit
# In editor: Project > Tools > GUT Panel > Run All
extends Node

func _ready() -> void:
	print("GUT Test Runner")
	print("  Editor: Project > Tools > GUT Panel > Run All")
	print("  CLI: godot --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests -gexit")
	get_tree().quit()
