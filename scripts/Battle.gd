extends Control

# Battle scene - handles loop execution and enemy management

signal battle_won
signal battle_lost

@onready var wave_label: Label = $VBox/TopBar/WaveLabel
@onready var hp_label: Label = $VBox/TopBar/HPLabel
@onready var resources_label: Label = $VBox/TopBar/ResourcesLabel
@onready var grid_container: GridContainer = $VBox/BattleArea/GridContainer
@onready var loop_display: HBoxContainer = $VBox/LoopDisplay
@onready var status_label: Label = $VBox/StatusLabel
@onready var queue_labels: Array[Label] = [
	$VBox/BattleArea/SpawnQueueContainer/QueueLabel0,
	$VBox/BattleArea/SpawnQueueContainer/QueueLabel1,
	$VBox/BattleArea/SpawnQueueContainer/QueueLabel2
]
@onready var combat_log: VBoxContainer = $CombatLog
@onready var log_container: VBoxContainer = $CombatLog/LogScroll/LogContainer

var grid_width: int = 6
var grid_height: int = 3
var grid_cells: Array[Array] = []
var enemies: Array[Enemy] = []
var loop_index: int = 0
var battle_over: bool = false
var current_block: int = 0
var wave_spawn_data: Array[Dictionary] = []
var spawn_timer: float = 0.0
var spawn_queue: Array[int] = [] # Queue count per lane
var combat_log_entries: Array[String] = []
const MAX_LOG_ENTRIES = 50

func _ready():
	_setup_ui()
	_setup_grid()

	# Connect to game state signals (only once)
	if not GameState.hero_hp_changed.is_connected(_update_hp_display):
		GameState.hero_hp_changed.connect(_update_hp_display)
	if not GameState.resources_changed.is_connected(_update_resources_display):
		GameState.resources_changed.connect(_update_resources_display)

	_start_battle()

func _input(event):
	if event.is_action_pressed("ui_accept"):  # Tab key
		_toggle_combat_log()

func _setup_ui():
	if not wave_label:
		_create_ui_structure()
	
	_update_display()

func _create_ui_structure():
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Top bar
	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	vbox.add_child(top_bar)
	
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(wave_label)
	
	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer1)
	
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(hp_label)
	
	resources_label = Label.new()
	resources_label.name = "ResourcesLabel"
	resources_label.add_theme_font_size_override("font_size", 16)
	top_bar.add_child(resources_label)
	
	# Battle area
	var battle_area = VBoxContainer.new()
	battle_area.name = "BattleArea"
	battle_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(battle_area)
	
	# Grid container
	grid_container = GridContainer.new()
	grid_container.name = "GridContainer"
	grid_container.columns = grid_width
	grid_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	battle_area.add_child(grid_container)
	
	# Loop display
	loop_display = HBoxContainer.new()
	loop_display.name = "LoopDisplay"
	loop_display.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(loop_display)
	
	# Status label
	status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(status_label)

func _setup_grid():
	# Initialize grid array
	grid_cells = []
	for y in range(grid_height):
		var row: Array[Control] = []
		for x in range(grid_width):
			row.append(null)
		grid_cells.append(row)
	
	# Create grid cells
	for y in range(grid_height):
		for x in range(grid_width):
			var cell = ColorRect.new()
			cell.custom_minimum_size = Vector2(80, 80)
			cell.color = Color.DARK_GRAY if (x + y) % 2 == 0 else Color.GRAY
			grid_container.add_child(cell)

func _start_battle():
	battle_over = false
	loop_index = 0
	current_block = 0
	spawn_timer = 0.0

	# Initialize grid and spawn queue
	GridManager.clear()
	spawn_queue = [0, 0, 0] # 3 lanes

	# Reset resources
	GameState.reset_resources()

	# Get wave data from room selection or fallback to EnemyDB
	if GameState.next_room.has("enemies"):
		_setup_room_enemies()
	else:
		wave_spawn_data = EnemyDB.get_wave_data(GameState.current_wave)
	
	# Create loop display
	_create_loop_display()
	
	# Start the battle loop
	_start_loop()

func _setup_room_enemies():
	# Convert room enemy list to spawn data format
	wave_spawn_data.clear()
	var room_enemies = GameState.next_room.get("enemies", [])

	for i in range(room_enemies.size()):
		var enemy_type = room_enemies[i]
		var spawn_data = {
			"enemy_id": enemy_type,
			"lane": i % 3,  # Distribute across lanes
			"delay": i * 2  # Stagger spawns
		}
		wave_spawn_data.append(spawn_data)

func _create_loop_display():
	# Clear existing display
	for child in loop_display.get_children():
		child.queue_free()
	
	# Create card displays for current deck
	for i in range(GameState.deck.size()):
		var card_id = GameState.deck[i]
		var card_display = _create_card_display(card_id, i)
		loop_display.add_child(card_display)

func _create_card_display(card_id: String, index: int) -> Control:
	var card_panel = Panel.new()
	card_panel.custom_minimum_size = Vector2(60, 80)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card_panel.add_child(vbox)

	var name_label = Label.new()
	name_label.text = card_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(name_label)

	# Highlight current card
	if index == loop_index:
		card_panel.modulate = Color.YELLOW

	return card_panel

func _start_loop():
	if battle_over:
		return
	
	status_label.text = "Loop " + str(loop_index + 1) + " - Executing cards..."
	
	# Execute all cards in sequence
	for i in range(GameState.deck.size()):
		await _execute_card(i)
		await get_tree().create_timer(0.3).timeout
	
	# Advance enemies
	_advance_enemies()
	
	# Check end conditions
	_check_battle_end()
	
	# Continue loop if battle not over
	if not battle_over:
		loop_index += 1
		current_block = 0  # Reset block each loop
		await get_tree().create_timer(0.5).timeout
		_start_loop()

func _execute_card(card_index: int):
	if card_index >= GameState.deck.size():
		return
	
	var card_id = GameState.deck[card_index]
	var card = Card.new(card_id)
	
	# Update loop display
	_update_loop_display(card_index)
	
	# Create battle context
	var battle_context = {
		"add_block": _add_block,
		"get_target_enemy": _get_target_enemy,
		"damage_enemies_in_lane": _damage_enemies_in_lane,
		"damage_all_enemies": _damage_all_enemies
	}
	
	# Execute card
	var result = card.execute(battle_context)

	if result.success:
		# Play card use sound
		AudioManager.play_card_use()

		# Handle damage
		if result.damage_dealt > 0:
			if "aoe_damage" in result.effects:
				_damage_all_enemies(result.damage_dealt)
				_add_log_entry(card_id + " → " + str(result.damage_dealt) + " dmg (All enemies)")
			else:
				var target = _get_target_enemy()
				if target:
					target.take_damage(result.damage_dealt)
					_add_log_entry(card_id + " → " + str(result.damage_dealt) + " dmg (" + target.enemy_id + " Lane " + str(target.grid_y) + ")")

		status_label.text = "Executed: " + card_id
	else:
		status_label.text = "Failed: " + card_id + " (requirements not met)"

func _update_loop_display(current_index: int):
	for i in range(loop_display.get_child_count()):
		var card_display = loop_display.get_child(i)
		if i == current_index:
			card_display.modulate = Color.YELLOW
		else:
			card_display.modulate = Color.WHITE

func _add_block(amount: int):
	current_block += amount

func _get_target_enemy() -> Enemy:
	# Find closest enemy to hero (lowest x position)
	var closest_enemy: Enemy = null
	var closest_distance = INF
	
	for enemy in enemies:
		if enemy.is_alive() and enemy.grid_x < closest_distance:
			closest_distance = enemy.grid_x
			closest_enemy = enemy
	
	return closest_enemy

func _damage_enemies_in_lane(lane: int, damage: int):
	for enemy in enemies:
		if enemy.is_alive() and enemy.is_in_lane(lane):
			enemy.take_damage(damage)

func _damage_all_enemies(damage: int):
	for enemy in enemies:
		if enemy.is_alive():
			enemy.take_damage(damage)

func _advance_enemies():
	status_label.text = "Enemies advancing..."

	# First, try to dequeue spawns
	_dequeue_spawns()

	# Spawn new enemies
	_spawn_enemies()

	# Move existing enemies
	var enemies_to_remove: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_alive():
			enemy.advance()
			_update_enemy_position(enemy)
		else:
			enemies_to_remove.append(enemy)

	# Remove dead enemies
	for enemy in enemies_to_remove:
		_remove_enemy(enemy)

func _spawn_enemies():
	# Spawn all enemies immediately at wave start
	if loop_index == 0 and not wave_spawn_data.is_empty():
		# Spawn all enemies for this wave immediately
		for spawn_data in wave_spawn_data:
			_try_spawn_enemy_immediate(spawn_data.enemy_id, spawn_data.lane)
		wave_spawn_data.clear()

func _try_spawn_enemy_immediate(enemy_id: String, preferred_lane: int):
	var spawn_col = GridManager.GRID_W - 1

	# Try lanes top to bottom starting from preferred
	for lane_offset in range(GridManager.GRID_H):
		var lane = (preferred_lane + lane_offset) % GridManager.GRID_H
		if GridManager.is_free(lane, spawn_col):
			_spawn_enemy(enemy_id, lane, spawn_col)
			return

	# If all lanes full, add to spawn queue
	spawn_queue[preferred_lane] += 1
	_update_spawn_queue_display()

func _try_spawn_enemy(enemy_id: String, lane: int):
	var spawn_col = GridManager.GRID_W - 1

	# Check if spawn position is free
	if GridManager.is_free(lane, spawn_col):
		_spawn_enemy(enemy_id, lane, spawn_col)
	else:
		# Try to find free lane
		var free_lane = GridManager.find_free_lane(lane, spawn_col)
		if free_lane != -1:
			_spawn_enemy(enemy_id, free_lane, spawn_col)
		else:
			# All lanes blocked, enqueue spawn
			spawn_queue[lane] += 1
			_update_spawn_queue_display()

func _spawn_enemy(enemy_id: String, lane: int, col: int):
	var enemy = Enemy.new()
	enemy.custom_minimum_size = Vector2(80, 80)
	enemy.initialize(enemy_id, col, lane)

	# Take the grid cell
	GridManager.take_cell(lane, col)

	# Connect signals
	enemy.enemy_died.connect(_on_enemy_died)
	enemy.enemy_reached_hero.connect(_on_enemy_reached_hero)

	enemies.append(enemy)
	add_child(enemy)
	_update_enemy_position(enemy)

	# Spawn effect
	enemy.scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(enemy, "scale", Vector2.ONE, 0.3)

func _dequeue_spawns():
	# Try to spawn one queued enemy per lane
	for lane in range(spawn_queue.size()):
		if spawn_queue[lane] > 0:
			var spawn_col = GridManager.GRID_W - 1
			if GridManager.is_free(lane, spawn_col):
				# Spawn a generic enemy (we'll need to track enemy types in queue later)
				_spawn_enemy("Slime", lane, spawn_col)
				spawn_queue[lane] -= 1

	# Update queue display
	_update_spawn_queue_display()

func _update_spawn_queue_display():
	for i in range(queue_labels.size()):
		if i < spawn_queue.size() and spawn_queue[i] > 0:
			queue_labels[i].text = "+" + str(spawn_queue[i])
		else:
			queue_labels[i].text = ""

func _toggle_combat_log():
	combat_log.visible = not combat_log.visible
	if combat_log.visible:
		var tween = create_tween()
		combat_log.position.x = get_viewport().size.x
		tween.tween_property(combat_log, "position:x", get_viewport().size.x - 300, 0.3)
	else:
		var tween = create_tween()
		tween.tween_property(combat_log, "position:x", get_viewport().size.x, 0.3)

func _add_log_entry(text: String):
	combat_log_entries.append(text)

	# Keep only last MAX_LOG_ENTRIES
	if combat_log_entries.size() > MAX_LOG_ENTRIES:
		combat_log_entries = combat_log_entries.slice(-MAX_LOG_ENTRIES)

	# Update UI
	_update_log_display()

func _update_log_display():
	# Clear existing log labels
	for child in log_container.get_children():
		child.queue_free()

	# Add new labels for recent entries
	for entry in combat_log_entries:
		var label = Label.new()
		label.text = entry
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		log_container.add_child(label)

func _update_enemy_position(enemy: Enemy):
	var pos = enemy.get_grid_position()
	if pos.x >= 0 and pos.x < grid_width and pos.y >= 0 and pos.y < grid_height:
		var cell_index = pos.y * grid_width + pos.x
		if cell_index < grid_container.get_child_count():
			var cell = grid_container.get_child(cell_index)
			enemy.position = cell.position
			enemy.size = cell.size

func _remove_enemy(enemy: Enemy):
	enemies.erase(enemy)
	enemy.queue_free()

func _on_enemy_died(enemy: Enemy):
	_remove_enemy(enemy)

func _on_enemy_reached_hero(enemy: Enemy, damage: int):
	# Apply damage with block
	var actual_damage = max(0, damage - current_block)
	current_block = max(0, current_block - damage)

	if actual_damage > 0:
		GameState.damage_hero(actual_damage)
		_add_log_entry(enemy.enemy_id + " hit Hero for " + str(actual_damage) + " dmg")
	else:
		_add_log_entry(enemy.enemy_id + " attack blocked (" + str(damage) + " dmg)")

	# Remove enemy if it made contact (not ranged)
	if enemy.grid_x <= 0:
		_remove_enemy(enemy)

func _check_battle_end():
	# Check for defeat
	if GameState.hero_hp <= 0:
		battle_over = true
		status_label.text = "DEFEAT!"
		await get_tree().create_timer(1.0).timeout
		emit_signal("battle_lost")
		return
	
	# Check for victory (all enemies dead and no more spawns)
	if enemies.is_empty() and wave_spawn_data.is_empty():
		battle_over = true
		status_label.text = "VICTORY!"
		await get_tree().create_timer(1.0).timeout
		emit_signal("battle_won")

func _update_display():
	if wave_label:
		wave_label.text = "Wave " + str(GameState.current_wave)
	_update_hp_display()
	_update_resources_display()

func _update_hp_display(_new_hp: int = 0):
	if hp_label:
		hp_label.text = "HP: " + str(GameState.hero_hp) + "/" + str(GameState.max_hero_hp)

func _update_resources_display(_ammo: int = 0, _mana: int = 0):
	if resources_label:
		resources_label.text = "⚙️" + str(GameState.ammo) + " ✨" + str(GameState.mana)
