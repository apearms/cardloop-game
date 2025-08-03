extends Control
class_name PauseMenu

# Pause menu with save/load functionality

signal resume_game
signal quit_to_menu

@onready var resume_button: Button = $CenterContainer/VBox/ResumeButton
@onready var save_button: Button = $CenterContainer/VBox/SaveButton
@onready var load_button: Button = $CenterContainer/VBox/LoadButton
@onready var quit_button: Button = $CenterContainer/VBox/QuitButton

var save_file_path: String = "user://savegame.save"

func _ready():
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Initially hidden
	visible = false

func show_pause_menu():
	visible = true
	get_tree().paused = true

func hide_pause_menu():
	visible = false
	get_tree().paused = false

func _on_resume_pressed():
	hide_pause_menu()
	emit_signal("resume_game")

func _on_save_pressed():
	_save_game()

func _on_load_pressed():
	_load_game()

func _on_quit_pressed():
	hide_pause_menu()
	emit_signal("quit_to_menu")

func _save_game():
	var save_data = {
		"wave": GameState.current_wave,
		"hp": GameState.current_hp,
		"max_hp": GameState.max_hp,
		"ammo": GameState.current_ammo,
		"mana": GameState.current_mana,
		"deck": GameState.deck.duplicate(),
		"deck_all": GameState.deck_all.duplicate(),
		"artifacts": GameState.artifacts.duplicate()
	}
	
	var save_file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Game saved successfully")
	else:
		print("Failed to save game")

func _load_game():
	var save_file = FileAccess.open(save_file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			
			# Restore game state
			GameState.current_wave = save_data.get("wave", 1)
			GameState.current_hp = save_data.get("hp", 10)
			GameState.max_hp = save_data.get("max_hp", 10)
			GameState.current_ammo = save_data.get("ammo", 0)
			GameState.current_mana = save_data.get("mana", 0)
			GameState.deck = save_data.get("deck", [])
			GameState.deck_all = save_data.get("deck_all", [])
			GameState.artifacts = save_data.get("artifacts", [])
			
			print("Game loaded successfully")
			hide_pause_menu()
			emit_signal("resume_game")
		else:
			print("Failed to parse save file")
	else:
		print("No save file found")
