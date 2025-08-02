extends Control

# Reward screen - choose 1 of 3 random cards

signal reward_selected(card_id)

signal reward_done(selected_id)

var title_label: Label
var instruction_label: Label
var cards_container: HBoxContainer

var reward_cards: Array[String] = []

func _ready():
	_setup_ui()
	_generate_rewards()

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
	title_label.text = "TREASURE!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title_label)
	
	# Instructions
	instruction_label = Label.new()
	instruction_label.name = "InstructionLabel"
	instruction_label.text = "Choose one card to add to your deck:"
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(instruction_label)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)
	
	# Cards container
	cards_container = HBoxContainer.new()
	cards_container.name = "CardsContainer"
	cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_container.add_theme_constant_override("separation", 20)
	vbox.add_child(cards_container)

func _generate_rewards():
	# Check reward type from GameState
	var reward_type = GameState.pending_reward

	if reward_type == "relic":
		_generate_relic_rewards()
	else:
		_generate_card_rewards()

func _generate_card_rewards():
	# Generate 3 random cards (mix of common and rare)
	reward_cards.clear()

	# 70% chance for common, 30% for rare
	for i in range(3):
		var rarity = "common"
		if GameState.get_random_float() < 0.3:
			rarity = "rare"

		var available_cards = CardDB.get_cards_by_rarity(rarity)
		if not available_cards.is_empty():
			var random_card = available_cards[GameState.get_random_int(0, available_cards.size() - 1)]
			reward_cards.append(random_card)

	# Create card buttons
	_create_card_buttons()

func _generate_relic_rewards():
	# Generate 3 random artifacts whose category slot is empty
	var available_artifacts = []
	for artifact_id in ArtifactDB.artifacts.keys():
		var artifact = ArtifactDB.get_artifact(artifact_id)
		if artifact.has("category"):
			var category = artifact["category"]
			if not GameState.artifacts.has(category) or GameState.artifacts[category] == "":
				available_artifacts.append(artifact_id)

	# Select up to 3 random artifacts
	reward_cards.clear()
	for i in range(min(3, available_artifacts.size())):
		if available_artifacts.size() > 0:
			var random_index = GameState.get_random_int(0, available_artifacts.size() - 1)
			var artifact_id = available_artifacts[random_index]
			reward_cards.append(artifact_id)
			available_artifacts.remove_at(random_index)

	# Update UI for relic rewards
	title_label.text = "RELIC CHAMBER!"
	instruction_label.text = "Choose one artifact:"

	# Create relic buttons
	_create_relic_buttons()

func _create_card_buttons():
	# Clear existing buttons
	for child in cards_container.get_children():
		child.queue_free()

	# Create button for each reward card
	for i in range(reward_cards.size()):
		var card_id = reward_cards[i]
		var card_button = _create_card_button(card_id, i)
		cards_container.add_child(card_button)

func _create_relic_buttons():
	# Clear existing buttons
	for child in cards_container.get_children():
		child.queue_free()

	# Create button for each reward artifact
	for i in range(reward_cards.size()):
		var artifact_id = reward_cards[i]
		var relic_button = _create_relic_button(artifact_id, i)
		cards_container.add_child(relic_button)

func _create_card_button(card_id: String, _index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 250)
	
	# Create card display
	var vbox = VBoxContainer.new()
	button.add_child(vbox)
	
	# Card name
	var name_label = Label.new()
	name_label.text = CardDB.get_card_name(card_id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	# Card cost
	var card = Card.new(card_id)
	var cost_label = Label.new()
	cost_label.text = card.get_cost_text()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(cost_label)
	
	# Card description
	var desc_label = Label.new()
	desc_label.text = card.get_display_description()
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)
	
	# Rarity indicator
	var rarity_label = Label.new()
	var rarity = card.get_rarity()
	rarity_label.text = "(" + rarity.capitalize() + ")"
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 10)
	
	# Color based on rarity
	match rarity:
		"rare":
			rarity_label.add_theme_color_override("font_color", Color.GOLD)
		"consumable":
			rarity_label.add_theme_color_override("font_color", Color.CYAN)
		_:
			rarity_label.add_theme_color_override("font_color", Color.WHITE)
	
	vbox.add_child(rarity_label)

	# Add buttons for deck/reserve choice
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_container)

	var deck_button = Button.new()
	deck_button.text = "Add to Deck"
	deck_button.custom_minimum_size = Vector2(80, 30)
	deck_button.pressed.connect(_on_card_to_deck.bind(card_id))
	button_container.add_child(deck_button)



	return button

func _create_relic_button(artifact_id: String, _index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(200, 250)

	# Create artifact display
	var vbox = VBoxContainer.new()
	button.add_child(vbox)

	# Artifact icon
	var icon_rect = TextureRect.new()
	icon_rect.texture = ArtifactDB.get_icon(artifact_id)
	icon_rect.custom_minimum_size = Vector2(64, 64)
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_rect)

	# Artifact name
	var name_label = Label.new()
	name_label.text = artifact_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)

	# Artifact description
	var artifact = ArtifactDB.get_artifact(artifact_id)
	var desc_label = Label.new()
	desc_label.text = artifact.get("desc", "No description")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(desc_label)

	# Category indicator
	var category_label = Label.new()
	var category = artifact.get("category", "unknown")
	category_label.text = "(" + category.capitalize() + ")"
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	category_label.add_theme_font_size_override("font_size", 10)
	category_label.add_theme_color_override("font_color", Color.GOLD)
	vbox.add_child(category_label)

	# Connect button
	button.pressed.connect(_on_relic_selected.bind(artifact_id))

	return button

func _on_card_to_deck(card_id: String):
	emit_signal("reward_selected", card_id)
	emit_signal("reward_done", card_id)

func _on_relic_selected(artifact_id: String):
	emit_signal("reward_done", artifact_id)
