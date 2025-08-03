extends Control
class_name DeckCardIcon

# Deck card icon for the deck panel - smaller version of CardSlot

signal icon_drag_started(card_id)
signal icon_drag_ended(card_id, global_position)

@onready var background: Panel = $Background
@onready var name_label: Label = $VBox/NameLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var uses_label: Label = $VBox/UsesLabel

var card_id: String = ""
var is_dragging: bool = false
var drag_preview: Control = null
var last_highlighted_slot: CardSlot = null

func _ready():
	custom_minimum_size = Vector2(64, 85)
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func _process(_delta):
	if is_dragging and drag_preview:
		# Update drag preview position
		drag_preview.global_position = get_global_mouse_position() - drag_preview.size / 2

		# Handle drag-over highlighting
		var prep_screen = get_tree().get_first_node_in_group("prep_screen")
		if prep_screen and prep_screen.has_method("_find_loop_slot_at"):
			var current_slot = prep_screen._find_loop_slot_at(get_global_mouse_position())

			# Clear previous highlight
			if last_highlighted_slot and last_highlighted_slot != current_slot:
				last_highlighted_slot.set_drag_over_highlight(false)

			# Set new highlight
			if current_slot and current_slot != last_highlighted_slot:
				current_slot.set_drag_over_highlight(true)

			last_highlighted_slot = current_slot

func set_card(id: String):
	card_id = id
	if id == "" or id == null:
		_show_empty_icon()
	else:
		_show_card_icon(id)

func _show_card_icon(id: String):
	var card = Card.new(id)

	# Update labels (with null checks for timing issues)
	if name_label:
		name_label.text = card.get_name()
		name_label.visible = true

	if cost_label:
		cost_label.text = card.get_cost_text()
		cost_label.visible = true

	if uses_label:
		uses_label.text = card.get_uses_text()
		uses_label.visible = true

	# Set tooltip with card info
	var card_name = CardDB.get_card_name(id)
	var card_desc = CardDB.get_card_description(id)
	tooltip_text = card_name + "\n" + card_desc
	
	# Set background color based on rarity
	var rarity = card.get_rarity()
	var rarity_colors = {
		"common": Color.WHITE,
		"rare": Color.GOLD,
		"consumable": Color.CYAN
	}
	_set_background_color(rarity_colors.get(rarity, Color.WHITE))

func _show_empty_icon():
	if name_label:
		name_label.visible = false
	if cost_label:
		cost_label.visible = false
	if uses_label:
		uses_label.visible = false
	tooltip_text = ""
	_set_background_color(Color.DARK_GRAY)

func _set_background_color(color: Color):
	if background:
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.6, 0.6, 0.6, 1)
		background.add_theme_stylebox_override("panel", style)

func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_drag(event.position)
			else:
				_end_drag()

func _start_drag(_start_pos: Vector2):
	if card_id == "" or card_id == null:
		return
		
	is_dragging = true
	_create_drag_preview()
	emit_signal("icon_drag_started", card_id)

func _end_drag():
	if is_dragging:
		is_dragging = false

		# Clear any remaining highlight
		if last_highlighted_slot:
			last_highlighted_slot.set_drag_over_highlight(false)
			last_highlighted_slot = null

		var global_pos = global_position + get_global_mouse_position() - global_position
		emit_signal("icon_drag_ended", card_id, global_pos)
		_destroy_drag_preview()

func _create_drag_preview():
	if drag_preview:
		_destroy_drag_preview()
	
	# Create a duplicate of this icon for preview
	drag_preview = duplicate()
	drag_preview.z_index = 100
	drag_preview.modulate = Color(1.0, 1.0, 1.0, 0.8)
	get_tree().root.add_child(drag_preview)

func _destroy_drag_preview():
	if drag_preview:
		drag_preview.queue_free()
		drag_preview = null

func _on_mouse_entered():
	if not is_dragging:
		scale = Vector2(1.1, 1.1)

func _on_mouse_exited():
	if not is_dragging:
		scale = Vector2.ONE

func get_card_id() -> String:
	return card_id
