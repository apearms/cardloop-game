extends Node

# Enemy database - loads and manages enemy definitions and wave spawning

var enemies: Dictionary = {}

func _ready():
	load_enemies()

# Load enemy definitions from JSON file
func load_enemies():
	var file = FileAccess.open("res://data/enemies.json", FileAccess.READ)
	if file == null:
		print("Error: Could not load enemies.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing enemies.json: ", json.get_error_message())
		return
	
	enemies = json.data
	print("Loaded ", enemies.size(), " enemy types")

# Get enemy data by ID
func get_enemy(enemy_id: String) -> Dictionary:
	if enemies.has(enemy_id):
		return enemies[enemy_id]
	else:
		print("Warning: Enemy not found: ", enemy_id)
		return {}

# Generate wave spawn data for a given wave number
func get_wave_data(wave_number: int) -> Array[Dictionary]:
	var spawn_data: Array[Dictionary] = []
	
	match wave_number:
		1:
			# Wave 1: 3 slimes
			spawn_data = [
				{"enemy_id": "Slime", "lane": 0, "delay": 0.0},
				{"enemy_id": "Slime", "lane": 1, "delay": 0.5},
				{"enemy_id": "Slime", "lane": 2, "delay": 1.0}
			]
		2:
			# Wave 2: 2 slimes, 2 runners
			spawn_data = [
				{"enemy_id": "Slime", "lane": 0, "delay": 0.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.3},
				{"enemy_id": "Slime", "lane": 2, "delay": 0.6},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.0}
			]
		3:
			# Wave 3: Mixed group (treasure wave)
			spawn_data = [
				{"enemy_id": "Runner", "lane": 0, "delay": 0.0},
				{"enemy_id": "Slime", "lane": 1, "delay": 0.2},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.4},
				{"enemy_id": "Slime", "lane": 1, "delay": 0.8},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.2}
			]
		4:
			# Wave 4: More runners
			spawn_data = [
				{"enemy_id": "Runner", "lane": 0, "delay": 0.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.2},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.4},
				{"enemy_id": "Slime", "lane": 1, "delay": 0.8},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.0},
				{"enemy_id": "Runner", "lane": 2, "delay": 1.2}
			]
		5:
			# Wave 5: First tank appears
			spawn_data = [
				{"enemy_id": "Tank", "lane": 1, "delay": 0.0},
				{"enemy_id": "Runner", "lane": 0, "delay": 0.5},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.5},
				{"enemy_id": "Slime", "lane": 0, "delay": 1.0},
				{"enemy_id": "Slime", "lane": 2, "delay": 1.0}
			]
		6:
			# Wave 6: Rest wave - moderate difficulty
			spawn_data = [
				{"enemy_id": "Slime", "lane": 0, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 1, "delay": 0.3},
				{"enemy_id": "Slime", "lane": 2, "delay": 0.6},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.0},
				{"enemy_id": "Runner", "lane": 2, "delay": 1.2}
			]
		7:
			# Wave 7: Treasure wave - challenging
			spawn_data = [
				{"enemy_id": "Tank", "lane": 0, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 2, "delay": 0.2},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.5},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.8},
				{"enemy_id": "Slime", "lane": 0, "delay": 1.2},
				{"enemy_id": "Slime", "lane": 2, "delay": 1.2}
			]
		8:
			# Wave 8: Heavy assault
			spawn_data = [
				{"enemy_id": "Runner", "lane": 0, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 1, "delay": 0.1},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.2},
				{"enemy_id": "Runner", "lane": 0, "delay": 0.5},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.7},
				{"enemy_id": "Tank", "lane": 1, "delay": 1.0},
				{"enemy_id": "Slime", "lane": 0, "delay": 1.5},
				{"enemy_id": "Slime", "lane": 2, "delay": 1.5}
			]
		9:
			# Wave 9: Pre-boss gauntlet
			spawn_data = [
				{"enemy_id": "Tank", "lane": 0, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 1, "delay": 0.1},
				{"enemy_id": "Tank", "lane": 2, "delay": 0.2},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.8},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.0},
				{"enemy_id": "Runner", "lane": 2, "delay": 1.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 1.3}
			]
		10:
			# Wave 10: Boss
			spawn_data = [
				{"enemy_id": "Boss", "lane": 1, "delay": 0.0}
			]
		11:
			# Wave 11: Mixed enemies
			spawn_data = [
				{"enemy_id": "Tank", "lane": 0, "delay": 0.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.5},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.8},
				{"enemy_id": "Slime", "lane": 0, "delay": 1.2},
				{"enemy_id": "Slime", "lane": 1, "delay": 1.5}
			]
		12:
			# Wave 12: Tank heavy
			spawn_data = [
				{"enemy_id": "Tank", "lane": 0, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 2, "delay": 0.5},
				{"enemy_id": "Runner", "lane": 1, "delay": 1.0}
			]
		13:
			# Wave 13: Runner swarm
			spawn_data = [
				{"enemy_id": "Runner", "lane": 0, "delay": 0.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 0.3},
				{"enemy_id": "Runner", "lane": 2, "delay": 0.6},
				{"enemy_id": "Runner", "lane": 0, "delay": 1.0},
				{"enemy_id": "Runner", "lane": 1, "delay": 1.3},
				{"enemy_id": "Runner", "lane": 2, "delay": 1.6}
			]
		14:
			# Wave 14: Elite mix
			spawn_data = [
				{"enemy_id": "Tank", "lane": 1, "delay": 0.0},
				{"enemy_id": "Tank", "lane": 0, "delay": 0.8},
				{"enemy_id": "Tank", "lane": 2, "delay": 1.6}
			]
		15:
			# Wave 15: Final Boss
			spawn_data = [
				{"enemy_id": "Boss", "lane": 1, "delay": 0.0}
			]
		_:
			# Default: random enemies
			spawn_data = generate_random_wave(wave_number)
	
	return spawn_data

# Generate a random wave for waves beyond 10
func generate_random_wave(wave_number: int) -> Array[Dictionary]:
	var spawn_data: Array[Dictionary] = []
	var enemy_count = min(3 + wave_number, 8)
	
	var enemy_types = ["Slime", "Runner"]
	if wave_number >= 5:
		enemy_types.append("Tank")
	
	for i in range(enemy_count):
		var enemy_type = enemy_types[GameState.get_random_int(0, enemy_types.size() - 1)]
		var lane = GameState.get_random_int(0, 2)
		var delay = i * 0.3 + GameState.get_random_float() * 0.2
		
		spawn_data.append({
			"enemy_id": enemy_type,
			"lane": lane,
			"delay": delay
		})
	
	return spawn_data

# Get enemy display name
func get_enemy_name(enemy_id: String) -> String:
	return enemy_id  # For now, use ID as display name
