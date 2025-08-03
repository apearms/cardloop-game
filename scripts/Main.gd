extends Control

# Main scene controller - handles scene transitions and game flow

@onready var title_screen: Control = $TitleScreen
@onready var game_container: Control = $GameContainer

var current_scene: Node = null

# Scene paths
const DRAFT_SCENE = "res://scenes/ui/CardDraftScene.tscn"
const PREP_SCENE = "res://scenes/ui/PrepScreen.tscn"
const BATTLE_SCENE = "res://scenes/battle/Battle.tscn"
const ROOM_SELECT_SCENE = "res://scenes/ui/RoomSelectScene.tscn"
const REWARD_SCENE = "res://scenes/ui/RewardScreen.tscn"
const REST_SCENE = "res://scenes/ui/RestScreen.tscn"
const END_SCENE = "res://scenes/ui/EndScreen.tscn"

func _ready():
	# Set up title screen
	_setup_title_screen()
	
	# Connect to game state signals
	GameState.hero_hp_changed.connect(_on_hero_hp_changed)
	
	# Show title screen initially
	show_title_screen()

func _setup_title_screen():
	# Create title screen if it doesn't exist
	if not title_screen:
		title_screen = Control.new()
		title_screen.name = "TitleScreen"
		title_screen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(title_screen)
	
	# Clear existing children
	for child in title_screen.get_children():
		child.queue_free()
	
	# Create title UI with CenterContainer
	var center_container = CenterContainer.new()
	center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_screen.add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	center_container.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "LOOP CARDS"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title_label)
	
	# Subtitle
	var subtitle_label = Label.new()
	subtitle_label.text = "A Loop-Based Card Autobattler"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(subtitle_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 50)
	vbox.add_child(spacer)
	
	# Start button
	var start_button = Button.new()
	start_button.text = "START GAME"
	start_button.custom_minimum_size = Vector2(200, 50)
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(_on_start_game)
	vbox.add_child(start_button)

	# Continue button
	var continue_button = Button.new()
	continue_button.text = "CONTINUE GAME"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	continue_button.disabled = not SaveManager.has_valid_save()
	continue_button.pressed.connect(_on_continue_game)
	vbox.add_child(continue_button)

	# Exit button
	var exit_button = Button.new()
	exit_button.text = "EXIT GAME"
	exit_button.custom_minimum_size = Vector2(200, 50)
	exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	exit_button.pressed.connect(_on_exit_game)
	vbox.add_child(exit_button)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Craft a loop of 8 cards, then watch your hero battle through 10 waves!\nSurvive the final boss to win."
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instructions.custom_minimum_size = Vector2(600, 0)
	vbox.add_child(instructions)
	
	# Create game container if it doesn't exist
	if not game_container:
		game_container = Control.new()
		game_container.name = "GameContainer"
		game_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		game_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		add_child(game_container)

func show_title_screen():
	title_screen.visible = true
	game_container.visible = false
	
	# Clear any current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

func _on_start_game():
	AudioManager.play_button_click()

	# Reset game state
	GameState.reset_game()

	# Hide title screen
	title_screen.visible = false
	game_container.visible = true

	# Start with prep screen
	load_scene(PREP_SCENE)

func _on_continue_game():
	AudioManager.play_button_click()

	# Load saved game
	if SaveManager.load_game():
		# Hide title screen
		title_screen.visible = false
		game_container.visible = true

		# Start with prep screen
		load_scene(PREP_SCENE)

func _on_exit_game():
	AudioManager.play_button_click()
	get_tree().quit()

func load_scene(scene_path: String):
	# Clear current scene
	if current_scene:
		current_scene.queue_free()
		current_scene = null

	# Load new scene
	var scene_resource = load(scene_path)
	if scene_resource:
		current_scene = scene_resource.instantiate()
		game_container.add_child(current_scene)

		# Scene loaded successfully

		# Connect scene-specific signals
		_connect_scene_signals()
	else:
		print("Error: Could not load scene: ", scene_path)

func _connect_scene_signals():
	if not current_scene:
		return
	
	# Connect common signals based on scene type
	if current_scene.has_signal("start_battle"):
		current_scene.start_battle.connect(_on_start_battle)
	
	if current_scene.has_signal("battle_won"):
		current_scene.battle_won.connect(_on_battle_won)
	
	if current_scene.has_signal("battle_lost"):
		current_scene.battle_lost.connect(_on_battle_lost)
	
	if current_scene.has_signal("reward_selected"):
		current_scene.reward_selected.connect(_on_reward_selected)

	if current_scene.has_signal("reward_done"):
		current_scene.reward_done.connect(_on_reward_done)


	
	if current_scene.has_signal("rest_choice_made"):
		current_scene.rest_choice_made.connect(_on_rest_choice_made)
	
	if current_scene.has_signal("return_to_title"):
		current_scene.return_to_title.connect(_on_return_to_title)

	if current_scene.has_signal("draft_complete"):
		current_scene.draft_complete.connect(_on_draft_complete)

	if current_scene.has_signal("room_selected"):
		current_scene.room_selected.connect(_on_room_selected)

func _on_draft_complete():
	load_scene(PREP_SCENE)

func _on_room_selected():
	# Room selected, start battle
	load_scene(BATTLE_SCENE)

func _on_reward_done(selected_id: String = ""):
	# Handle artifact rewards
	if selected_id != "":
		var artifact = ArtifactDB.get_artifact(selected_id)
		if artifact.has("category"):
			var category = artifact["category"]
			GameState.artifacts[category] = selected_id

	load_scene(PREP_SCENE)

func _on_start_battle():
	load_scene(ROOM_SELECT_SCENE)

func _on_battle_won():
	GameState.advance_wave()
	
	# Check for game completion
	if GameState.current_wave > GameState.max_waves:
		_show_victory()
		return
	
	# Determine reward based on room just cleared
	var room_data = GameState.next_room
	if room_data.has("reward_type") and room_data.reward_type != "heal":
		# Show reward screen first
		load_scene(REWARD_SCENE)
	else:
		# Go directly to prep screen
		load_scene(PREP_SCENE)

func _on_battle_lost():
	_show_defeat()

func _on_reward_selected(card_id: String):
	# Add card to deck_all - player will drag to loop manually
	GameState.add_card_to_deck(card_id)
	load_scene(PREP_SCENE)



func _on_rest_choice_made(choice: String):
	match choice:
		"heal":
			GameState.heal_hero(6)
		"rare_card":
			var rare_cards = CardDB.get_cards_by_rarity("rare")
			if not rare_cards.is_empty():
				var random_card = rare_cards[GameState.get_random_int(0, rare_cards.size() - 1)]
				# Add card to deck_all - player will drag to loop manually
				GameState.add_card_to_deck(random_card)
	
	load_scene(PREP_SCENE)

func _on_return_to_title():
	show_title_screen()

func _show_victory():
	load_scene(END_SCENE)
	if current_scene and current_scene.has_method("set_victory"):
		current_scene.set_victory(true)

func _show_defeat():
	load_scene(END_SCENE)
	if current_scene and current_scene.has_method("set_victory"):
		current_scene.set_victory(false)

func _on_hero_hp_changed(new_hp: int):
	# Check for death
	if new_hp <= 0:
		_show_defeat()
