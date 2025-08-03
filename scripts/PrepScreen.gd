extends Control

# Prep screen - loop builder interface with 8 card slots

signal start_battle

var pause_menu_scene = preload("res://scenes/ui/PauseMenu.tscn")
var pause_menu: PauseMenu

@onready var wave_label: Label = $CenterContainer/VBox/TopBar/WaveLabel
@onready var hp_label: Label = $CenterContainer/VBox/TopBar/HPLabel
# Removed replace_banner - using drag system now
@onready var loop_container: HBoxContainer = $CenterContainer/VBox/LoopStrip/LoopContainer
@onready var run_button: Button = $CenterContainer/VBox/BottomBar/RunButton
@onready var relic_bar: HBoxContainer = $CenterContainer/VBox/RelicBar
@onready var deck_slots: GridContainer = $CenterContainer/VBox/DeckPanel/ScrollContainer/DeckSlots

var card_slots: Array[CardSlot] = []
var deck_card_icon_scene = preload("res://scenes/ui/DeckCardIcon.tscn")

func _ready():
	# Add to group for drag system
	add_to_group("prep_screen")

	_setup_ui()
	_setup_card_slots()
	_setup_relic_bar()
	_refresh_deck_panel()
	_update_display()
	_setup_pause_menu()

	# Ensure deck panel is refreshed after layout
	call_deferred("_refresh_deck_panel")

	# Connect to game state changes
	GameState.deck_changed.connect(_update_card_slots)
	GameState.deck_changed.connect(_refresh_deck_panel)
	GameState.hero_hp_changed.connect(_update_hp_display)
	GameState.artifacts_changed.connect(_setup_relic_bar)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		GlobalPause.toggle_pause()

func _setup_ui():
	# Connect buttons
	if run_button and not run_button.pressed.is_connected(_on_run_button_pressed):
		run_button.pressed.connect(_on_run_button_pressed)

func _setup_pause_menu():
	pause_menu = pause_menu_scene.instantiate()
	add_child(pause_menu)
	pause_menu.resume_game.connect(_on_pause_resume)
	pause_menu.quit_to_menu.connect(_on_pause_quit)

func _toggle_pause_menu():
	if pause_menu.visible:
		pause_menu.hide_pause_menu()
	else:
		pause_menu.show_pause_menu()

func _on_pause_resume():
	# Game automatically resumes when pause menu is hidden
	pass

func _on_pause_quit():
	# Return to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")



func _create_ui_structure():
	# Main VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Top bar with wave and HP info
	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	vbox.add_child(top_bar)
	
	wave_label = Label.new()
	wave_label.name = "WaveLabel"
	wave_label.text = "Wave 1"
	wave_label.add_theme_font_size_override("font_size", 24)
	top_bar.add_child(wave_label)
	
	var spacer1 = Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(spacer1)
	
	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.text = "HP: 20/20"
	hp_label.add_theme_font_size_override("font_size", 18)
	top_bar.add_child(hp_label)
	
	# Title
	var title_label = Label.new()
	title_label.text = "Build Your Loop"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title_label)
	
	# Instructions
	var instructions = Label.new()
	instructions.text = "Drag cards to rearrange your 8-card loop. Click RUN when ready!"
	instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instructions.add_theme_font_size_override("font_size", 16)
	vbox.add_child(instructions)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Loop container
	loop_container = HBoxContainer.new()
	loop_container.name = "LoopContainer"
	loop_container.alignment = BoxContainer.ALIGNMENT_CENTER
	loop_container.add_theme_constant_override("separation", 10)
	vbox.add_child(loop_container)
	
	# Spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer3)
	
	# Bottom bar with run button
	var bottom_bar = HBoxContainer.new()
	bottom_bar.name = "BottomBar"
	bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(bottom_bar)
	
	run_button = Button.new()
	run_button.name = "RunButton"
	run_button.text = "RUN LOOP"
	run_button.custom_minimum_size = Vector2(200, 60)
	run_button.add_theme_font_size_override("font_size", 24)
	bottom_bar.add_child(run_button)

func _setup_card_slots():
	# Clear existing slots
	card_slots.clear()
	for child in loop_container.get_children():
		child.queue_free()

	# Create slots based on current loop pattern
	var pattern = GameState.current_slot_pattern()
	var slot_index = 0

	for subloop_index in range(pattern.size()):
		var subloop_size = pattern[subloop_index]

		# Create a container for this subloop
		var subloop_container = HBoxContainer.new()
		subloop_container.name = "SubLoop" + str(subloop_index)
		loop_container.add_child(subloop_container)

		# Add slots for this subloop
		for i in range(subloop_size):
			var slot = CardSlot.new()
			slot.slot_index = slot_index
			slot.subloop_index = subloop_index
			slot.name = "slot_" + str(slot_index)

			# Connect slot signals
			if not slot.drag_ended.is_connected(_on_card_drag_ended):
				slot.drag_ended.connect(_on_card_drag_ended)
			if not slot.card_clicked.is_connected(_on_card_clicked):
				slot.card_clicked.connect(_on_card_clicked)

			subloop_container.add_child(slot)
			card_slots.append(slot)
			slot_index += 1

func _update_display():
	_update_wave_display()
	_update_hp_display()
	_update_card_slots()

func _update_wave_display():
	if wave_label:
		wave_label.text = "Wave " + str(GameState.current_wave)

func _update_hp_display(_new_hp: int = 0):
	if hp_label:
		hp_label.text = "HP: " + str(GameState.hero_hp) + "/" + str(GameState.max_hero_hp)

func _update_card_slots():
	# Ensure deck has enough slots (fill with empty strings)
	var max_size = GameState.max_deck_size()
	while GameState.deck.size() < max_size:
		GameState.deck.append("")

	# Dynamic card size (loop slots)
	if loop_container:
		var slot_w := min(150, loop_container.size.x / GameState.max_deck_size() - 8)
		for slot in card_slots:
			slot.custom_minimum_size = Vector2(slot_w, slot_w * 1.34)

	# Update each slot with corresponding deck card (up to max_deck_size)
	for i in range(min(card_slots.size(), max_size)):
		var slot = card_slots[i]
		if i < GameState.deck.size():
			slot.set_card(GameState.deck[i])
		else:
			slot.set_card("")

func _on_card_drag_ended(from_slot: int, to_slot: int):
	if from_slot != to_slot and to_slot >= 0 and to_slot < card_slots.size():
		# Check if both slots are in the same subloop
		var from_subloop = card_slots[from_slot].subloop_index
		var to_subloop = card_slots[to_slot].subloop_index

		if from_subloop == to_subloop:
			# Swap cards in deck (only within same subloop)
			GameState.swap_deck_cards(from_slot, to_slot)

func _on_card_clicked(slot_index: int):
	# Right-click to remove card from slot and return to deck_all
	if slot_index >= 0 and slot_index < card_slots.size():
		var slot = card_slots[slot_index]
		var card_id = slot.get_card_id()

		if not card_id.is_empty():
			# Remove card from deck and add to deck_all
			GameState.deck[slot_index] = ""
			GameState.deck_all.append(card_id)

			# Refresh UI
			_refresh_deck_panel()
			_update_card_slots()
			GameState.emit_signal("deck_changed")

# Removed replacement mode functions - now using drag system

func _on_slot_clicked(_slot_index: int, _event: InputEvent):
	# Slot click handling for future use
	pass





func _on_run_button_pressed():
	emit_signal("start_battle")

func _setup_relic_bar():
	if not relic_bar:
		return

	# Clear existing relic slots
	for child in relic_bar.get_children():
		child.queue_free()

	# Create slots for each artifact category
	var categories = ["loop", "armor", "shield", "weapon", "magic", "consumable"]
	for category in categories:
		var slot = TextureRect.new()
		slot.custom_minimum_size = Vector2(32, 32)
		slot.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL

		# Check if we have an artifact in this category
		if GameState.artifacts.has(category) and GameState.artifacts[category] != "":
			var artifact_id = GameState.artifacts[category]
			var icon_texture = ArtifactDB.get_icon(artifact_id)
			if icon_texture == null:
				icon_texture = ArtifactDB.get_placeholder_icon(category)
			slot.texture = icon_texture
			# Set tooltip with artifact description
			var artifact = ArtifactDB.get_artifact(artifact_id)
			slot.tooltip_text = artifact.get("desc", "No description")

			# Add right-click to discard
			slot.gui_input.connect(_on_artifact_input.bind(category))
		else:
			# Empty slot - dark frame
			_create_empty_artifact_slot(slot)
			# Set tooltip for empty slot
			slot.tooltip_text = "Empty %s slot" % category.capitalize()

		relic_bar.add_child(slot)

func _create_artifact_placeholder(slot: TextureRect, category: String):
	# Create a simple colored texture as placeholder
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	var color = Color.GRAY
	match category:
		"loop": color = Color.BLUE
		"armor": color = Color.BROWN
		"shield": color = Color.SILVER
		"weapon": color = Color.RED
		"magic": color = Color.PURPLE
		"consumable": color = Color.GREEN

	image.fill(color)
	var texture = ImageTexture.new()
	texture.set_image(image)
	slot.texture = texture

func _on_artifact_input(category: String, event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_show_discard_dialog(category)

func _show_discard_dialog(category: String):
	var artifact_id = GameState.artifacts.get(category, "")
	if artifact_id == "":
		return

	var dialog = AcceptDialog.new()
	dialog.title = "Discard Artifact"
	dialog.dialog_text = "Discard " + artifact_id + "?"
	add_child(dialog)
	dialog.confirmed.connect(_discard_artifact.bind(category))
	dialog.popup_centered()

func _discard_artifact(category: String):
	GameState.artifacts[category] = ""
	GameState.emit_signal("artifacts_changed")

func _create_empty_artifact_slot(slot: TextureRect):
	# Dark frame for empty slot
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.DIM_GRAY)
	var texture = ImageTexture.new()
	texture.set_image(image)
	slot.texture = texture

func _refresh_deck_panel():
	if not deck_slots:
		return

	# Clear existing deck icons
	for child in deck_slots.get_children():
		child.queue_free()

	# Always keep GridContainer visible
	deck_slots.visible = true

	# Set dynamic columns based on container width
	if loop_container:
		deck_slots.columns = max(1, loop_container.size.x / 70)

	if GameState.deck_all.size() == 0:
		# Show "(Deck empty)" label when no cards
		var empty_label = Label.new()
		empty_label.text = "(Deck empty)"
		empty_label.modulate = Color.GRAY
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		deck_slots.add_child(empty_label)
	else:
		# Create icon for each card in deck_all
		for id in GameState.deck_all:
			var icon = deck_card_icon_scene.instantiate()
			# Connect drag signals
			icon.icon_drag_started.connect(_on_icon_drag_started)
			icon.icon_drag_ended.connect(_on_icon_drag_ended)
			deck_slots.add_child(icon)
			# Set card data after adding to scene tree (ensures @onready vars are ready)
			icon.call_deferred("set_card", id)

func _on_icon_drag_started(_card_id: String):
	# Visual feedback for drag start
	pass

func _on_icon_drag_ended(card_id: String, pos: Vector2):
	var target_slot := _find_loop_slot_at(pos)
	if target_slot != null:
		# Swap logic
		var old_id := GameState.deck[target_slot.slot_index]
		GameState.deck[target_slot.slot_index] = card_id
		GameState.deck_all.erase(card_id)
		if old_id != "":
			GameState.deck_all.append(old_id)

		# Refresh UI after swapping
		_refresh_deck_panel()
		_update_card_slots()
		GameState.emit_signal("deck_changed")

func _find_loop_slot_at(global_pos: Vector2) -> CardSlot:
	for slot in card_slots:
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(global_pos):
			return slot
	return null
