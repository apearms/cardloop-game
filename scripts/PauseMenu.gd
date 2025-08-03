extends Control
class_name PauseMenu

# Pause menu with save/load functionality

signal resume_game
signal quit_to_menu

@onready var resume_button: Button = $CenterContainer/VBox/ResumeButton
@onready var save_button: Button = $CenterContainer/VBox/SaveButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton

var save_file_path: String = "user://savegame.save"

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Register with GlobalPause
	GlobalPause.register_pause_menu(self)

	# Initially hidden
	visible = false

func show_pause_menu():
	visible = true
	GlobalPause._pause()

func hide_pause_menu():
	visible = false
	GlobalPause._unpause()

func _on_resume_pressed():
	hide_pause_menu()
	emit_signal("resume_game")

func _on_save_pressed():
	_save_game()

func _on_quit_pressed():
	hide_pause_menu()
	emit_signal("quit_to_menu")

func _save_game():
	var save_data = {
		"wave": GameState.current_wave,
		"hp": GameState.hero_hp,
		"max_hp": GameState.max_hero_hp,
		"ammo": GameState.ammo,
		"mana": GameState.mana,
		"deck": GameState.deck.duplicate(),
		"deck_all": GameState.deck_all.duplicate(),
		"artifacts": GameState.artifacts.duplicate(),
		"finished": false
	}
	
	var save_file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved successfully")
	else:
		print("Failed to save game")

# Load Game functionality removed - use Continue from main menu instead
