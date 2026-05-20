# scenes/hand_area.gd
class_name HandArea
extends Control

signal play_pressed()
signal pass_pressed()
signal ultimate_requested()
signal restart_requested()
signal card_toggled(card: Card, selected: bool)

@onready var card_container: HBoxContainer = $CardContainer
@onready var status_label: Label = $StatusLabel
@onready var ai_card_container: HBoxContainer = $PlayZone/AIRow/AICardContainer
@onready var player_card_container: HBoxContainer = $PlayZone/PlayerRow/PlayerCardContainer
@onready var restart_button: Button = $RestartButton
@onready var play_button: Button = $ButtonRow/PlayButton
@onready var pass_button: Button = $ButtonRow/PassButton
@onready var ultimate_button: Button = $ButtonRow/UltimateButton

var _selected: Array[Card] = []
var _card_buttons: Dictionary = {}

func _ready() -> void:
	play_button.pressed.connect(func() -> void: play_pressed.emit())
	pass_button.pressed.connect(func() -> void: pass_pressed.emit())
	ultimate_button.pressed.connect(func() -> void: ultimate_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())
	ultimate_button.disabled = true
	restart_button.visible = false

func show_restart_button() -> void:
	restart_button.visible = true

func hide_restart_button() -> void:
	restart_button.visible = false

func render_hand(cards: Array[Card]) -> void:
	for child in card_container.get_children():
		child.queue_free()
	_card_buttons.clear()
	_selected.clear()
	var sorted := _sort_cards(cards)
	for c in sorted:
		var btn := Button.new()
		btn.text = _card_label(c)
		btn.toggle_mode = true
		btn.toggled.connect(func(pressed: bool) -> void: _on_card_toggled(c, pressed))
		card_container.add_child(btn)
		_card_buttons[c] = btn

# who: "ai" or "player"
func show_played_cards(who: String, cards: Array[Card], action_name: String) -> void:
	var container := ai_card_container if who == "ai" else player_card_container
	for child in container.get_children():
		child.queue_free()
	var header := Label.new()
	header.text = "[%s] " % action_name
	container.add_child(header)
	for c in cards:
		var lbl := Label.new()
		lbl.text = _card_label(c) + " "
		container.add_child(lbl)

func clear_play_zone() -> void:
	for child in ai_card_container.get_children():
		child.queue_free()
	for child in player_card_container.get_children():
		child.queue_free()

func _sort_cards(cards: Array[Card]) -> Array[Card]:
	var suit_order := {"clubs": 0, "diamonds": 1, "hearts": 2, "spades": 3, "joker": 4}
	var sorted := cards.duplicate()
	sorted.sort_custom(func(a: Card, b: Card) -> bool:
		if a.number != b.number:
			return a.number < b.number
		return suit_order.get(a.suit, 0) < suit_order.get(b.suit, 0)
	)
	return sorted

func _card_label(c: Card) -> String:
	if c.suit == "joker":
		return "大王" if c.number == 17 else "小王"
	var n_str := str(c.number)
	match c.number:
		11: n_str = "J"
		12: n_str = "Q"
		13: n_str = "K"
		14: n_str = "A"
		15: n_str = "2"
	var suit_map: Dictionary = {"spades": "♠", "hearts": "♥", "diamonds": "♦", "clubs": "♣"}
	var suit_char: String = suit_map.get(c.suit, "?") as String
	return "%s%s" % [suit_char, n_str]

func _on_card_toggled(c: Card, pressed: bool) -> void:
	if pressed:
		if not c in _selected:
			_selected.append(c)
	else:
		_selected.erase(c)
	card_toggled.emit(c, pressed)

func get_selected_cards() -> Array[Card]:
	return _selected.duplicate()

func clear_selection() -> void:
	_selected.clear()
	for c in _card_buttons:
		(_card_buttons[c] as Button).button_pressed = false

func set_last_play_text(text: String) -> void:
	status_label.text = text

func set_ultimate_enabled(enabled: bool) -> void:
	ultimate_button.disabled = not enabled

func set_buttons_enabled(play_enabled: bool, pass_enabled: bool) -> void:
	play_button.disabled = not play_enabled
	pass_button.disabled = not pass_enabled
