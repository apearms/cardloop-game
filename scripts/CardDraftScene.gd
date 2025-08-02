extends Control

# Card draft scene - pick 4 starting cards

signal draft_complete

@onready var title_label: Label = $VBox/TitleLabel
@onready var progress_label: Label = $VBox/ProgressLabel
@onready var card_buttons: Array[Button] = [
	$VBox/CardContainer/Card1,
	$VBox/CardContainer/Card2,
	$VBox/CardContainer/Card3
]

var current_pick: int = 0
var total_picks: int = 4
var available_cards: Array[String] = []

func _ready():
	_setup_available_cards()
	_start_draft()

func _setup_available_cards():
	# Get all common cards for drafting
	available_cards = []
	for card_id in CardDB.cards.keys():
		var card_data = CardDB.get_card(card_id)
		if card_data.get("rarity", "common") == "common":
			available_cards.append(card_id)

func _start_draft():
	current_pick = 0
	GameState.deck.clear()
	_present_next_choice()

func _present_next_choice():
	if current_pick >= total_picks:
		_complete_draft()
		return
	
	# Update progress
	progress_label.text = "Pick 1 of 3 (" + str(current_pick + 1) + "/" + str(total_picks) + ")"
	
	# Shuffle and pick 3 random cards
	var shuffled_cards = available_cards.duplicate()
	shuffled_cards.shuffle()
	
	var choices = shuffled_cards.slice(0, 3)
	
	# Setup card buttons
	for i in range(card_buttons.size()):
		var button = card_buttons[i]
		var card_id = choices[i]
		var card_data = CardDB.get_card(card_id)
		
		# Set button text with card info
		var button_text = card_data.get("name", card_id)
		button_text += "\n" + card_data.get("description", "")
		button.text = button_text
		
		# Connect button signal
		if button.pressed.is_connected(_on_card_selected):
			button.pressed.disconnect(_on_card_selected)
		button.pressed.connect(_on_card_selected.bind(card_id))

func _on_card_selected(card_id: String):
	# Add selected card to deck
	GameState.deck.append(card_id)
	current_pick += 1
	
	# Present next choice
	_present_next_choice()

func _complete_draft():
	# Ensure deck matches loop pattern size
	var pattern = GameState.current_slot_pattern()
	var target_size = pattern.reduce(func(a, b): return a + b, 0)
	
	# Fill remaining slots with basic cards if needed
	while GameState.deck.size() < target_size:
		GameState.deck.append("Strike")
	
	# Emit completion signal
	emit_signal("draft_complete")
