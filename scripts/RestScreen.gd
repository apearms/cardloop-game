extends Control

# Rest screen - heal or get a rare card

signal rest_choice_made(choice)

var title_label: Label
var instruction_label: Label
var choices_container: VBoxContainer

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
	title_label.text = "REST AREA"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title_label)
	
	# Instructions
	instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.text = "Choose your rest option:"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(instruction_label)
	
	# Current HP display
	var hp_label = Label.new()
	hp_label.text = "Current HP: " + str(GameState.hero_hp) + "/" + str(GameState.max_hero_hp)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(hp_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)
	
	# Choices container
	choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_container.add_theme_constant_override("separation", 15)
	vbox.add_child(choices_container)
	
	# Create choice buttons
	_create_choice_buttons()

func _create_choice_buttons():
	# Heal option
	var heal_button = Button.new()
	heal_button.text = "REST AND HEAL\nRecover 6 HP"
	heal_button.custom_minimum_size = Vector2(300, 80)
	heal_button.add_theme_font_size_override("font_size", 16)
	heal_button.pressed.connect(_on_heal_selected)
	choices_container.add_child(heal_button)
	
	# Disable heal if already at max HP
	if GameState.hero_hp >= GameState.max_hero_hp:
		heal_button.disabled = true
		heal_button.text = "REST AND HEAL\n(Already at max HP)"
	
	# Rare card option
	var rare_button = Button.new()
	rare_button.text = "STUDY ANCIENT TEXTS\nGain a random rare card"
	rare_button.custom_minimum_size = Vector2(300, 80)
	rare_button.add_theme_font_size_override("font_size", 16)
	rare_button.pressed.connect(_on_rare_card_selected)
	choices_container.add_child(rare_button)

func _on_heal_selected():
	emit_signal("rest_choice_made", "heal")

func _on_rare_card_selected():
	emit_signal("rest_choice_made", "rare_card")
