# Test script to verify game functionality
# Run this in Godot to test basic game systems

extends SceneTree

func _init():
	print("Testing Loop Cards game systems...")
	
	# Test GameState
	test_game_state()
	
	# Test CardDB
	test_card_db()
	
	# Test EnemyDB
	test_enemy_db()
	
	print("All tests completed!")
	quit()

func test_game_state():
	print("\n=== Testing GameState ===")
	
	# Test initial state
	print("Initial HP: ", GameState.hero_hp)
	print("Initial deck size: ", GameState.deck.size())
	print("Initial wave: ", GameState.current_wave)
	
	# Test resource management
	GameState.add_ammo(3)
	GameState.add_mana(2)
	print("After adding resources - Ammo: ", GameState.ammo, " Mana: ", GameState.mana)
	
	# Test spending resources
	var spent_ammo = GameState.spend_ammo(2)
	var spent_mana = GameState.spend_mana(1)
	print("Spent ammo: ", spent_ammo, " Spent mana: ", spent_mana)
	print("Remaining - Ammo: ", GameState.ammo, " Mana: ", GameState.mana)

func test_card_db():
	print("\n=== Testing CardDB ===")
	
	# Test card loading
	print("Cards loaded: ", CardDB.cards.size())
	
	# Test specific cards
	var strike_card = CardDB.get_card("Strike")
	print("Strike card damage: ", strike_card.get("damage", 0))
	
	var gunfire_card = CardDB.get_card("Gunfire")
	print("Gunfire card cost: ", gunfire_card.get("cost", {}))
	
	# Test card usage
	print("Can use Strike: ", CardDB.can_use_card("Strike"))
	print("Strike uses remaining: ", CardDB.get_remaining_uses("Strike"))

func test_enemy_db():
	print("\n=== Testing EnemyDB ===")
	
	# Test enemy loading
	print("Enemies loaded: ", EnemyDB.enemies.size())
	
	# Test specific enemy
	var slime_data = EnemyDB.get_enemy("Slime")
	print("Slime HP: ", slime_data.get("hp", 0))
	print("Slime speed: ", slime_data.get("speed", 0))
	
	# Test wave generation
	var wave1_data = EnemyDB.get_wave_data(1)
	print("Wave 1 enemies: ", wave1_data.size())
	
	var wave10_data = EnemyDB.get_wave_data(10)
	print("Wave 10 (boss) enemies: ", wave10_data.size())
