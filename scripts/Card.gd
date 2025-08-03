extends Resource
class_name Card

# Card resource class for storing card data and logic

var card_id: String
var card_data: Dictionary

func _init(id: String = ""):
	card_id = id
	if not id.is_empty():
		card_data = CardDB.get_card(id)

# Get card property with default value
func get_property(property: String, default_value = null):
	return card_data.get(property, default_value)

# Check if card can be used
func can_use() -> bool:
	return CardDB.can_use_card(card_id)

# Execute card effect
func execute(_battle_context: Dictionary = {}) -> Dictionary:
	var result = {
		"success": false,
		"damage_dealt": 0,
		"resources_spent": {"ammo": 0, "mana": 0},
		"effects": []
	}
	
	if not can_use():
		return result
	
	# Pay costs
	var cost = get_property("cost", {})
	if cost.has("ammo") and cost.ammo > 0:
		if not GameState.spend_ammo(cost.ammo):
			return result
		result.resources_spent.ammo = cost.ammo
	
	if cost.has("mana") and cost.mana > 0:
		if not GameState.spend_mana(cost.mana):
			# Refund ammo if mana payment failed
			GameState.add_ammo(result.resources_spent.ammo)
			return result
		result.resources_spent.mana = cost.mana
	
	# Use the card
	if not CardDB.use_card(card_id):
		# Refund costs if card use failed
		GameState.add_ammo(result.resources_spent.ammo)
		GameState.add_mana(result.resources_spent.mana)
		return result
	
	result.success = true
	
	# Apply effects based on card type
	var card_type = get_property("type", "utility")
	
	var execution_result: Dictionary = {}

	match card_type:
		"attack":
			execution_result = _execute_attack(_battle_context)
		"resource":
			execution_result = _execute_resource()
		"defense":
			execution_result = _execute_defense(_battle_context)
		"consumable":
			execution_result = _execute_consumable(_battle_context)
		"utility":
			execution_result = _execute_utility()
		_:
			execution_result = {"effects": ["unknown"]}

	# Merge the execution result into the main result
	_merge_results(result, execution_result)

	return result

# Helper function to merge dictionary results
func _merge_results(target: Dictionary, source: Dictionary):
	for key in source:
		target[key] = source[key]

# Execute attack card
func _execute_attack(_battle_context: Dictionary = {}) -> Dictionary:
	var result = {"damage_dealt": 0, "effects": []}

	var damage = get_property("damage", 0)
	var range_type = get_property("range", "ranged")  # Default to ranged for backwards compatibility

	if damage > 0:
		var battle = _battle_context.get("battle")
		if battle:
			if range_type == "melee":
				# Melee: only damage enemy at col 1
				if battle.has_method("damage_front_enemy"):
					var actual_damage = battle.damage_front_enemy(damage)
					result.damage_dealt = actual_damage
			elif range_type == "ranged":
				# Ranged: damage frontmost enemy regardless of distance
				if battle.has_method("damage_frontmost_enemy"):
					var actual_damage = battle.damage_frontmost_enemy(damage)
					result.damage_dealt = actual_damage

		if get_property("aoe", false):
			result.effects.append("aoe_damage")
		else:
			result.effects.append("single_damage")

	return result

# Execute resource card
func _execute_resource() -> Dictionary:
	var result = {"effects": []}
	
	var ammo_gain = get_property("ammo_gain", 0)
	if ammo_gain > 0:
		GameState.add_ammo(ammo_gain)
		result.effects.append("gain_ammo")
	
	var mana_gain = get_property("mana_gain", 0)
	if mana_gain > 0:
		GameState.add_mana(mana_gain)
		result.effects.append("gain_mana")
	
	return result

# Execute defense card
func _execute_defense(_battle_context: Dictionary = {}) -> Dictionary:
	var result = {"effects": []}
	
	var block = get_property("block", 0)
	if block > 0:
		# Add block to battle context (handled by battle system)
		if _battle_context.has("add_block"):
			_battle_context.add_block.call(block)
		result.effects.append("block")
	
	return result

# Execute consumable card
func _execute_consumable(_battle_context: Dictionary = {}) -> Dictionary:
	var result = {"effects": []}
	
	# Healing
	var heal = get_property("heal", 0)
	if heal > 0:
		GameState.heal_hero(heal)
		result.effects.append("heal")
	
	# Damage (like bomb)
	var damage = get_property("damage", 0)
	if damage > 0:
		result.damage_dealt = damage
		if get_property("aoe", false):
			result.effects.append("aoe_damage")
		else:
			result.effects.append("single_damage")
	
	# Block (like flash)
	var block = get_property("block", 0)
	if block > 0:
		if _battle_context.has("add_block"):
			_battle_context.add_block.call(block)
		result.effects.append("block")
	
	return result

# Execute utility card (skip, etc.)
func _execute_utility() -> Dictionary:
	return {"effects": ["utility"]}

# Get display information
func get_display_name() -> String:
	return CardDB.get_card_name(card_id)

func get_display_description() -> String:
	return CardDB.get_card_description(card_id)

func get_remaining_uses() -> int:
	return CardDB.get_remaining_uses(card_id)

func is_single_copy() -> bool:
	return get_property("single_copy", false)

func get_rarity() -> String:
	return get_property("rarity", "common")

func get_cost_text() -> String:
	var cost = get_property("cost", {})
	var cost_parts: Array[String] = []

	if cost.has("ammo") and cost.ammo > 0:
		cost_parts.append(str(cost.ammo) + " ⚙️")

	if cost.has("mana") and cost.mana > 0:
		cost_parts.append(str(cost.mana) + " ✨")

	if cost_parts.is_empty():
		return "Free"
	else:
		return " ".join(cost_parts)

func get_uses_text() -> String:
	var uses = get_property("uses", 0)
	if uses > 0:
		return str(uses) + " uses"
	else:
		return "∞"
