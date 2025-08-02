extends Control

# End screen - victory or defeat

signal return_to_title

var title_label: Label
var message_label: Label
var stats_label: Label
var buttons_container: HBoxContainer

var is_victory: bool = false

func _ready():
	_setup_ui()

func _setup_ui():
	if not title_label:
		_create_ui_structure()

func _create_ui_structure():
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	vbox.add_child(title_label)
	
	# Message
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(message_label)
	
	# Spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer1)
	
	# Stats
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(stats_label)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer2)
	
	# Buttons container
	buttons_container = HBoxContainer.new()
	buttons_container.name = "ButtonsContainer"
	buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons_container.add_theme_constant_override("separation", 20)
	vbox.add_child(buttons_container)
	
	# Create buttons
	_create_buttons()

func _create_buttons():
	# Retry button
	var retry_button = Button.new()
	retry_button.text = "PLAY AGAIN"
	retry_button.custom_minimum_size = Vector2(150, 50)
	retry_button.add_theme_font_size_override("font_size", 16)
	retry_button.pressed.connect(_on_retry_pressed)
	buttons_container.add_child(retry_button)
	
	# Quit button
	var quit_button = Button.new()
	quit_button.text = "MAIN MENU"
	quit_button.custom_minimum_size = Vector2(150, 50)
	quit_button.add_theme_font_size_override("font_size", 16)
	quit_button.pressed.connect(_on_quit_pressed)
	buttons_container.add_child(quit_button)

func set_victory(victory: bool):
	is_victory = victory
	_update_display()

	# Play appropriate sound
	if is_victory:
		AudioManager.play_victory()
	else:
		AudioManager.play_defeat()

func _update_display():
	if is_victory:
		title_label.text = "VICTORY!"
		title_label.add_theme_color_override("font_color", Color.GOLD)
		message_label.text = "You have defeated the boss and saved the realm!"
		
		stats_label.text = "Final Stats:\n" + \
			"Waves Completed: " + str(GameState.max_waves) + "\n" + \
			"Final HP: " + str(GameState.hero_hp) + "/" + str(GameState.max_hero_hp) + "\n" + \
			"Cards in Deck: " + str(GameState.deck.size())
	else:
		title_label.text = "DEFEAT"
		title_label.add_theme_color_override("font_color", Color.RED)
		message_label.text = "Your hero has fallen... but you can try again!"
		
		stats_label.text = "Final Stats:\n" + \
			"Waves Reached: " + str(GameState.current_wave) + "/" + str(GameState.max_waves) + "\n" + \
			"Final HP: " + str(GameState.hero_hp) + "/" + str(GameState.max_hero_hp) + "\n" + \
			"Cards in Deck: " + str(GameState.deck.size())

func _on_retry_pressed():
	# Reset game and return to title
	GameState.reset_game()
	emit_signal("return_to_title")

func _on_quit_pressed():
	emit_signal("return_to_title")
