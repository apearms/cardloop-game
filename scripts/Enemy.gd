extends Control
class_name Enemy

# Enemy node for the battle grid

signal enemy_died(enemy)
signal enemy_reached_hero(enemy, damage)

var background: ColorRect
var hp_label: Label
var name_label: Label
var sprite: Sprite2D

var enemy_id: String = ""
var enemy_data: Dictionary = {}
var current_hp: int = 0
var max_hp: int = 0
var grid_x: int = 0
var grid_y: int = 0
var speed: int = 1
var contact_damage: int = 1
var ranged_damage: int = 0
var ranged_interval: int = 0
var loop_count: int = 0

func _ready():
	if not background:
		_create_ui_structure()

	# Ensure always visible
	visible = true
	modulate = Color(1, 1, 1, 1)

func _create_ui_structure():
	# Background
	background = ColorRect.new()
	background.name = "Background"
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(background)
	
	# VBox for layout
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Name label
	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)
	
	# HP label
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(hp_label)

	# Sprite for enemy visual
	sprite = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.z_index = 10  # Higher than background & damage flashes
	add_child(sprite)

	# Create a simple colored texture as placeholder
	_create_placeholder_texture()

	# Ensure always visible at end of _ready
	sprite.modulate = Color.WHITE
	sprite.visible = true
	visible = true

func initialize(enemy_type: String, x: int, y: int):
	# Ensure UI structure exists
	if not background:
		_create_ui_structure()

	enemy_id = enemy_type
	enemy_data = EnemyDB.get_enemy(enemy_type)
	grid_x = x
	grid_y = y

	# Set stats from data
	max_hp = enemy_data.get("hp", 1)
	current_hp = max_hp
	speed = enemy_data.get("speed", 1)
	contact_damage = enemy_data.get("contact_damage", 1)
	ranged_damage = enemy_data.get("ranged_damage", 0)
	ranged_interval = enemy_data.get("ranged_interval", 0)

	# Update display
	name_label.text = EnemyDB.get_enemy_name(enemy_id)
	_update_hp_display()
	
	# Set color
	var color_string = enemy_data.get("color", "#FFFFFF")
	background.color = Color(color_string)

	# Set sprite texture based on enemy type
	_set_sprite_texture(enemy_id)

func take_damage(damage: int):
	current_hp = max(0, current_hp - damage)
	_update_hp_display()

	# Audio feedback
	AudioManager.play_enemy_hit()

	# Visual feedback
	_flash_damage()

	if current_hp <= 0:
		# Release grid cell before dying
		GridManager.release_cell(grid_y, grid_x)
		AudioManager.play_enemy_death()
		emit_signal("enemy_died", self)

func _update_hp_display():
	if hp_label:
		hp_label.text = str(current_hp) + "/" + str(max_hp)

func _flash_damage():
	# Simple damage flash effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func advance():
	# Try to move forward
	var new_x = grid_x - speed

	# Check if reached hero
	if new_x <= 0:
		GridManager.release_cell(grid_y, grid_x)
		emit_signal("enemy_reached_hero", self, contact_damage)
		return

	# Check if target cell is free
	if GridManager.is_free(grid_y, new_x):
		# Move forward
		GridManager.release_cell(grid_y, grid_x)
		grid_x = new_x
		GridManager.take_cell(grid_y, grid_x)
	else:
		# Try lateral lane shift
		var free_lane = GridManager.find_free_lane(grid_y, new_x)
		if free_lane != -1:
			# Move to free lane
			GridManager.release_cell(grid_y, grid_x)
			grid_y = free_lane
			grid_x = new_x
			GridManager.take_cell(grid_y, grid_x)
		# If no free lane, wait this loop (no movement)

	loop_count += 1
	
	# Ranged attack
	if ranged_damage > 0 and ranged_interval > 0:
		if loop_count % ranged_interval == 0:
			_perform_ranged_attack()

func _perform_ranged_attack():
	# Boss ranged attack
	emit_signal("enemy_reached_hero", self, ranged_damage)
	
	# Visual feedback for ranged attack
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.YELLOW, 0.2)
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func get_grid_position() -> Vector2i:
	return Vector2i(grid_x, grid_y)

func is_in_lane(lane: int) -> bool:
	return grid_y == lane

func is_alive() -> bool:
	return current_hp > 0

func _create_placeholder_texture():
	# Create a simple 32x32 colored texture as placeholder
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)  # Default white, will be colored per enemy type
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

func _set_sprite_texture(enemy_type: String):
	# Create colored placeholder based on enemy type
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	var color = Color.WHITE

	match enemy_type:
		"Slime":
			color = Color.GREEN
		"Runner":
			color = Color.ORANGE
		"Tank":
			color = Color.BROWN
		"Boss":
			color = Color.PURPLE
		_:
			color = Color.WHITE

	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	sprite.texture = texture

	# Position sprite in center of enemy
	sprite.position = Vector2(40, 40)  # Center of 80x80 enemy cell

	# Set z_index based on lane for proper layering
	sprite.z_index = grid_y

	# Add spawn animation
	_animate_spawn()

func _animate_spawn():
	# Start with small scale, tween to normal scale (alpha stays 1)
	sprite.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.2)

func get_enemy_id() -> String:
	return enemy_id
