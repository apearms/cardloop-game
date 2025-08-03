extends Control

# Room selection scene - choose difficulty and rewards

signal room_selected

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var wave_label: Label = $CenterContainer/VBox/WaveLabel
@onready var room_container: VBoxContainer = $CenterContainer/VBox/RoomContainer

var room_options: Array[Dictionary] = []

func _ready():
	_setup_room_options()
	_create_room_buttons()

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		GlobalPause.toggle_pause()

func _setup_room_options():
	room_options.clear()
	
	var current_wave = GameState.current_wave
	wave_label.text = "Wave " + str(current_wave)
	
	# Generate room options based on wave
	if current_wave <= 3:
		# Early waves: 2-3 options
		room_options = [
			{
				"difficulty": "Easy",
				"enemies": ["Slime", "Slime"],
				"reward_type": "heal",
				"reward_value": 3,
				"description": "2 Slimes • Heal 3 HP"
			},
			{
				"difficulty": "Medium", 
				"enemies": ["Slime", "Runner"],
				"reward_type": "card",
				"reward_value": null,
				"description": "Slime + Runner • Choose Card"
			}
		]
	elif current_wave <= 7:
		# Mid waves: 3 options
		room_options = [
			{
				"difficulty": "Easy",
				"enemies": ["Slime", "Slime"],
				"reward_type": "heal",
				"reward_value": 4,
				"description": "2 Slimes • Heal 4 HP"
			},
			{
				"difficulty": "Medium",
				"enemies": ["Runner", "Runner"],
				"reward_type": "card",
				"reward_value": null,
				"description": "2 Runners • Choose Card"
			},
			{
				"difficulty": "Hard",
				"enemies": ["Tank", "Runner"],
				"reward_type": "artifact",
				"reward_value": null,
				"description": "Tank + Runner • Random Artifact"
			}
		]
	else:
		# Late waves: 3-4 options
		room_options = [
			{
				"difficulty": "Easy",
				"enemies": ["Runner", "Runner"],
				"reward_type": "heal",
				"reward_value": 5,
				"description": "2 Runners • Heal 5 HP"
			},
			{
				"difficulty": "Medium",
				"enemies": ["Tank", "Runner"],
				"reward_type": "card",
				"reward_value": null,
				"description": "Tank + Runner • Choose Card"
			},
			{
				"difficulty": "Hard",
				"enemies": ["Tank", "Tank"],
				"reward_type": "artifact",
				"reward_value": null,
				"description": "2 Tanks • Random Artifact"
			},
			{
				"difficulty": "Extreme",
				"enemies": ["Tank", "Runner", "Runner"],
				"reward_type": "artifact",
				"reward_value": null,
				"description": "Tank + 2 Runners • Random Artifact"
			}
		]

func _create_room_buttons():
	# Clear existing buttons
	for child in room_container.get_children():
		child.queue_free()
	
	# Create button for each room option
	for i in range(room_options.size()):
		var room_data = room_options[i]
		var button = Button.new()
		
		# Set button text
		var button_text = room_data.difficulty + " - Wave " + str(GameState.current_wave)
		button_text += "\n" + room_data.description
		button.text = button_text
		
		# Style button
		button.custom_minimum_size = Vector2(400, 80)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# Connect signal
		button.pressed.connect(_on_room_selected.bind(i))
		
		room_container.add_child(button)

func _on_room_selected(room_index: int):
	var room_data = room_options[room_index]

	# Create selected_room dictionary with all necessary data
	var selected_room = {
		"enemies": room_data.enemies,
		"reward_type": room_data.reward_type,
		"difficulty": room_data.difficulty
	}

	# Store room data in GameState for battle
	GameState.next_room = selected_room

	# Store pending reward for after battle
	GameState.pending_reward = room_data.reward_type

	# Grant heal reward immediately (others handled after battle)
	if room_data.reward_type == "heal":
		_grant_reward(room_data)

	# Emit signal to proceed
	emit_signal("room_selected")

func _grant_reward(room_data: Dictionary):
	match room_data.reward_type:
		"heal":
			var heal_amount = room_data.get("reward_value", 3)
			GameState.heal_hero(heal_amount)
			print("Healed for ", heal_amount, " HP")
		
		"card":
			# This will be handled by loading reward screen
			print("Card reward will be handled by reward screen")
		
		"artifact":
			# Grant random artifact (for now just print)
			print("Random artifact granted (not implemented yet)")
