extends Node

# Global game state manager
# Handles hero stats, deck, wave progression, and resources

# MAX_DECK_SIZE is now computed from current loop artifact

signal hero_hp_changed(new_hp)
signal resources_changed(ammo, mana)
signal deck_changed()

# Hero stats
var hero_hp: int = 20
var max_hero_hp: int = 20

# Resources (reset each battle)
var ammo: int = 0
var mana: int = 0

# Wave progression
var current_wave: int = 1
var max_waves: int = 15

# Deck (array of card IDs)
var deck: Array[String] = []      # active loop cards
var deck_all: Array[String] = []  # every owned card



# Artifacts (category -> id)
var artifacts := {"loop": "Loop-6"}

# Next room data for battle
var next_room: Dictionary = {}
var pending_reward: String = ""

# RNG seed for consistent randomness
var rng: RandomNumberGenerator

func _ready():
	# Initialize RNG
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Initialize starting deck
	reset_game()

# Reset game to starting state
func reset_game():
	hero_hp = max_hero_hp
	current_wave = 1
	ammo = 0
	mana = 0

	# Set starting artifact
	artifacts = {"loop": "Loop-6"}

	# Set starting deck with 4 basics
	deck_all = ["Strike", "Barrier", "Reload", "Gunfire"]
	deck = ["Strike", "Barrier", "Reload", "Gunfire"]   # first N = loop size
	
	emit_signal("hero_hp_changed", hero_hp)
	emit_signal("resources_changed", ammo, mana)
	emit_signal("deck_changed")

# Damage hero and check for death
func damage_hero(damage: int) -> bool:
	hero_hp = max(0, hero_hp - damage)
	emit_signal("hero_hp_changed", hero_hp)
	return hero_hp <= 0

# Heal hero
func heal_hero(amount: int):
	hero_hp = min(max_hero_hp, hero_hp + amount)
	emit_signal("hero_hp_changed", hero_hp)

# Reset resources at start of battle
func reset_resources():
	ammo = 0
	mana = 0
	emit_signal("resources_changed", ammo, mana)

# Modify resources
func add_ammo(amount: int):
	ammo = min(9, ammo + amount)
	emit_signal("resources_changed", ammo, mana)

func add_mana(amount: int):
	mana = min(9, mana + amount)
	emit_signal("resources_changed", ammo, mana)

func spend_ammo(amount: int) -> bool:
	if ammo >= amount:
		ammo -= amount
		emit_signal("resources_changed", ammo, mana)
		return true
	return false

func spend_mana(amount: int) -> bool:
	if mana >= amount:
		mana -= amount
		emit_signal("resources_changed", ammo, mana)
		return true
	return false

# Wave progression
func advance_wave():
	current_wave += 1

func is_boss_wave() -> bool:
	return current_wave == max_waves

func is_treasure_wave() -> bool:
	return current_wave == 3 or current_wave == 7

func is_rest_wave() -> bool:
	return current_wave == 6

# Artifact management
func current_slot_pattern() -> Array[int]:
	var artifact_data = ArtifactDB.get_artifact(artifacts["loop"])
	var pattern = artifact_data.get("slot_pattern", [8])
	var result: Array[int] = []
	for item in pattern:
		result.append(int(item))
	return result

func max_deck_size() -> int:
	return current_slot_pattern().reduce(func(a, b): return a + b, 0)

# Deck management
func can_add_card() -> bool:
	return deck.size() < max_deck_size()

func add_card_to_deck(card_id: String) -> bool:
	# Add to deck_all only - player decides when to put in loop
	deck_all.append(card_id)
	emit_signal("deck_changed")
	return true

func remove_card_from_deck(card_id: String):
	var index = deck.find(card_id)
	if index != -1:
		deck.remove_at(index)
		emit_signal("deck_changed")

func swap_deck_cards(index1: int, index2: int):
	if index1 >= 0 and index1 < deck.size() and index2 >= 0 and index2 < deck.size():
		var temp = deck[index1]
		deck[index1] = deck[index2]
		deck[index2] = temp
		emit_signal("deck_changed")

func replace_card(old_slot: int, new_id: String):
	if old_slot >= 0 and old_slot < deck.size():
		deck[old_slot] = new_id
		emit_signal("deck_changed")

# Get random number
func get_random_int(min_val: int, max_val: int) -> int:
	return rng.randi_range(min_val, max_val)

func get_random_float() -> float:
	return rng.randf()
