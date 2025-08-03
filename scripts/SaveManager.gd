extends Node

# Save/Load manager singleton

const SAVE_FILE_PATH = "user://savegame.save"

func has_valid_save() -> bool:
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not save_file:
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return false
	
	var save_data = json.data
	# Check if save is not finished
	return not save_data.get("finished", false)

func save_game():
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
	
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		return true
	return false

func load_game() -> bool:
	var save_file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not save_file:
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return false
	
	var save_data = json.data
	
	# Restore game state
	GameState.current_wave = save_data.get("wave", 1)
	GameState.hero_hp = save_data.get("hp", 20)
	GameState.max_hero_hp = save_data.get("max_hp", 20)
	GameState.ammo = save_data.get("ammo", 0)
	GameState.mana = save_data.get("mana", 0)
	GameState.deck = save_data.get("deck", [])
	GameState.deck_all = save_data.get("deck_all", [])
	GameState.artifacts = save_data.get("artifacts", {})
	
	# Mark as not finished when loading
	save_data["finished"] = false
	
	return true
