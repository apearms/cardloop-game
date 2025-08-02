extends Node

# Card database - loads and manages card definitions from JSON

var cards: Dictionary = {}
var card_uses: Dictionary = {}  # Track remaining uses for consumable cards

func _ready():
	load_cards()

# Load card definitions from JSON file
func load_cards():
	var file = FileAccess.open("res://data/cards.json", FileAccess.READ)
	if file == null:
		print("Error: Could not load cards.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing cards.json: ", json.get_error_message())
		return
	
	cards = json.data
	print("Loaded ", cards.size(), " cards")
	
	# Initialize uses for consumable cards
	reset_card_uses()

# Reset all card uses to their maximum
func reset_card_uses():
	card_uses.clear()
	for card_id in cards:
		var card = cards[card_id]
		if card.has("max_uses") and card.max_uses > 0:
			card_uses[card_id] = card.max_uses

# Get card data by ID
func get_card(card_id: String) -> Dictionary:
	if cards.has(card_id):
		return cards[card_id]
	else:
		print("Warning: Card not found: ", card_id)
		return {}

# Check if card has uses remaining
func has_uses(card_id: String) -> bool:
	var card = get_card(card_id)
	
	# Infinite uses
	if not card.has("max_uses") or card.max_uses == -1:
		return true
	
	# Check remaining uses
	return card_uses.get(card_id, 0) > 0

# Use a card (decrement uses if applicable)
func use_card(card_id: String) -> bool:
	if not has_uses(card_id):
		return false
	
	var card = get_card(card_id)
	if card.has("max_uses") and card.max_uses > 0:
		card_uses[card_id] = card_uses.get(card_id, 0) - 1
	
	return true

# Get remaining uses for a card
func get_remaining_uses(card_id: String) -> int:
	var card = get_card(card_id)
	
	# Infinite uses
	if not card.has("max_uses") or card.max_uses == -1:
		return -1
	
	return card_uses.get(card_id, 0)

# Check if card requirements are met
func can_use_card(card_id: String) -> bool:
	var card = get_card(card_id)
	
	# Check uses
	if not has_uses(card_id):
		return false
	
	# Check resource costs
	if card.has("cost"):
		var cost = card.cost
		if cost.has("ammo") and GameState.ammo < cost.ammo:
			return false
		if cost.has("mana") and GameState.mana < cost.mana:
			return false
	
	# Check charge requirement (skip first loop)
	if card.has("requires_charge") and card.requires_charge > 0:
		# This would need to be tracked per battle - simplified for now
		pass
	
	return true

# Get all cards of a specific rarity
func get_cards_by_rarity(rarity: String) -> Array[String]:
	var result: Array[String] = []
	for card_id in cards:
		var card = cards[card_id]
		if card.get("rarity", "common") == rarity:
			result.append(card_id)
	return result

# Get random cards for rewards
func get_random_cards(count: int, rarity: String = "") -> Array[String]:
	var available_cards: Array[String] = []
	
	if rarity.is_empty():
		available_cards = cards.keys()
	else:
		available_cards = get_cards_by_rarity(rarity)
	
	var result: Array[String] = []
	for i in range(min(count, available_cards.size())):
		if available_cards.is_empty():
			break
		
		var random_index = GameState.get_random_int(0, available_cards.size() - 1)
		var selected_card = available_cards[random_index]
		result.append(selected_card)
		available_cards.remove_at(random_index)
	
	return result

# Get card display name
func get_card_name(card_id: String) -> String:
	return card_id  # For now, use ID as display name

# Get card description
func get_card_description(card_id: String) -> String:
	var card = get_card(card_id)
	var desc = ""
	
	# Build description from card properties
	if card.has("damage"):
		desc += "Deal " + str(card.damage) + " damage. "
	
	if card.has("cost"):
		var cost = card.cost
		if cost.has("ammo") and cost.ammo > 0:
			desc += "Costs " + str(cost.ammo) + " ammo. "
		if cost.has("mana") and cost.mana > 0:
			desc += "Costs " + str(cost.mana) + " mana. "
	
	if card.has("max_uses") and card.max_uses > 0:
		desc += "(" + str(get_remaining_uses(card_id)) + " uses left) "
	
	return desc.strip_edges()
