extends Control
class_name CardSlot

# UI component for displaying and interacting with cards in the loop strip

signal card_clicked(slot_index)
signal card_selected(slot_index)
signal drag_started(slot_index)
signal drag_ended(slot_index, target_slot_index)

var background: Control
var card_name_label: Label
var cost_label: Label
var uses_label: Label


@export var slot_index: int = 0
@export var subloop_index: int = 0
var card_id: String = ""
var is_dragging: bool = false
var drag_offset: Vector2
var drag_preview: Control
var is_drag_highlighted: bool = false
var is_selected: bool = false
var click_start_time: float = 0.0
var click_threshold: float = 0.2  # Time threshold to distinguish click from drag

# Colors for different rarities
var rarity_colors = {
	"common": Color.WHITE,
	"rare": Color.GOLD,
	"consumable": Color.CYAN
}

func _ready():
	# Set fixed card size
	custom_minimum_size = Vector2(96, 128)
	mouse_filter = Control.MOUSE_FILTER_PASS

	# Only create UI structure if we don't have it already
	if not background:
		_create_ui_structure()

	# Connect signals
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

func _create_ui_structure():
	# Create background panel with border
	var background_panel = Panel.new()
	background_panel.name = "Background"
	background_panel.anchors_preset = Control.PRESET_FULL_RECT

	# Create dark gray style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.5, 0.5, 1)
	background_panel.add_theme_stylebox_override("panel", style)

	add_child(background_panel)

	# Store reference for compatibility
	background = background_panel

	# Create VBox for layout inside the panel
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.offset_left = 4
	vbox.offset_top = 4
	vbox.offset_right = -4
	vbox.offset_bottom = -4
	background_panel.add_child(vbox)

	# Create labels - only name, cost, and uses (no description)
	card_name_label = Label.new()
	card_name_label.name = "CardName"
	card_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_name_label.clip_contents = true
	card_name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(card_name_label)

	cost_label = Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(cost_label)

	uses_label = Label.new()
	uses_label.name = "UsesLabel"
	uses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	uses_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(uses_label)

func set_card(new_card_id: String):
	card_id = new_card_id
	update_display()

func update_display():
	if card_id.is_empty():
		_show_empty_slot()
		return
	
	var card = Card.new(card_id)

	# Show all labels for cards
	card_name_label.visible = true
	cost_label.visible = true
	uses_label.visible = true

	# Update labels
	card_name_label.text = card.get_display_name()
	cost_label.text = card.get_cost_text()

	# Show uses for consumables
	var remaining_uses = card.get_remaining_uses()
	if remaining_uses >= 0:
		uses_label.text = "(" + str(remaining_uses) + " uses)"
	else:
		uses_label.text = ""
	

	
	# Set background color based on rarity
	var rarity = card.get_rarity()
	_set_background_color(rarity_colors.get(rarity, Color.WHITE))
	
	# Dim if card can't be used
	if not card.can_use():
		modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		modulate = Color.WHITE

func _show_empty_slot():
	# Hide all labels for empty slots - show dark panel with silver border
	card_name_label.visible = false
	cost_label.visible = false
	uses_label.visible = false
	_set_empty_slot_style()
	modulate = Color.WHITE

func _set_empty_slot_style():
	# Create style with #777 border for empty slots
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color.DARK_GRAY
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color("#777777")  # Gray border for empty slots

	# Apply the style to the background
	background.add_theme_stylebox_override("panel", style_box)

func set_drag_over_highlight(enabled: bool):
	# Highlight empty slot during drag over
	if card_id == "":
		if enabled:
			modulate = Color(1, 1, 1, 0.6)  # Indicate drop target
		else:
			modulate = Color.WHITE  # Normal state

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				click_start_time = Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60
				_start_drag(event.position)
			else:
				var click_duration = (Time.get_time_dict_from_system()["second"] + Time.get_time_dict_from_system()["minute"] * 60) - click_start_time
				if click_duration < click_threshold and not is_dragging:
					# Short click - select/deselect
					_toggle_selection()
				_end_drag()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			emit_signal("card_clicked", slot_index)

	elif event is InputEventMouseMotion and is_dragging:
		_update_drag(event.position)

func _start_drag(mouse_pos: Vector2):
	if card_id.is_empty():
		return
	
	is_dragging = true
	drag_offset = mouse_pos
	emit_signal("drag_started", slot_index)

	# Create drag preview
	_create_drag_preview()

	# Visual feedback
	modulate = Color(1.0, 1.0, 1.0, 0.7)

func _update_drag(_mouse_pos: Vector2):
	if is_dragging and drag_preview:
		drag_preview.global_position = get_global_mouse_position() - drag_offset

func _end_drag():
	if not is_dragging:
		return
	
	is_dragging = false
	modulate = Color.WHITE

	# Destroy drag preview
	_destroy_drag_preview()

	# Find target slot
	var target_slot = _find_target_slot()
	emit_signal("drag_ended", slot_index, target_slot)

func _find_target_slot() -> int:
	# Get all CardSlot nodes in parent
	var parent_node = get_parent()
	if not parent_node:
		return slot_index
	
	var slots: Array[CardSlot] = []
	for child in parent_node.get_children():
		if child is CardSlot and child != self:
			slots.append(child)
	
	# Find closest slot
	var mouse_pos = get_global_mouse_position()
	var closest_slot = slot_index
	var closest_distance = INF
	
	for slot in slots:
		var distance = mouse_pos.distance_to(slot.global_position + slot.size / 2)
		if distance < closest_distance:
			closest_distance = distance
			closest_slot = slot.slot_index
	
	return closest_slot

func _set_background_color(color: Color):
	# Update the StyleBox background color
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color(1, 1, 1, 0.25)  # Light white border with 25% opacity

	# Apply the style to the background
	background.add_theme_stylebox_override("panel", style_box)

func _on_mouse_entered():
	if not is_dragging and not is_drag_highlighted and not is_selected:
		scale = Vector2(1.05, 1.05)

func _on_mouse_exited():
	if not is_dragging and not is_drag_highlighted and not is_selected:
		scale = Vector2.ONE

# Drag-over highlighting for empty slots
func _can_drop_data(_position: Vector2, _data) -> bool:
	# Only allow drops on empty slots
	return card_id == ""

func _drop_data(_position: Vector2, _data):
	# Handle drop - this will be managed by PrepScreen
	pass

func set_drag_highlight(enabled: bool):
	is_drag_highlighted = enabled
	if enabled and card_id == "":
		# Yellow highlight for empty slot during drag
		modulate = Color(1, 1, 0, 0.5)
		scale = Vector2(1.1, 1.1)
	else:
		# Reset to normal
		modulate = Color.WHITE
		scale = Vector2.ONE

func set_slot_index(index: int):
	slot_index = index

func _toggle_selection():
	if card_id.is_empty():
		return

	is_selected = not is_selected
	_update_selection_visual()
	emit_signal("card_selected", slot_index)

func _update_selection_visual():
	if is_selected:
		# Blue highlight for selected card
		modulate = Color(0.7, 0.7, 1.0, 1.0)
		scale = Vector2(1.1, 1.1)
	else:
		# Reset to normal
		modulate = Color.WHITE
		scale = Vector2.ONE

func set_selected(selected: bool):
	is_selected = selected
	_update_selection_visual()

func _create_drag_preview():
	if drag_preview:
		_destroy_drag_preview()

	# Create a duplicate of this slot for preview
	drag_preview = duplicate()
	drag_preview.z_index = 100  # Ensure it's on top
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.8)
	get_tree().root.add_child(drag_preview)

func _destroy_drag_preview():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func get_card_id() -> String:
	return card_id

func _get_placeholder_card() -> Texture2D:
	var img = Image.create(96, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.4, 0.4, 0.4))
	var tex = ImageTexture.create_from_image(img)
	return tex
