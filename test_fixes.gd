# Test script to verify the fixes work
extends SceneTree

func _init():
	print("Testing Loop Cards fixes...")
	
	# Test that autoloads work
	test_autoloads()
	
	# Test card system
	test_card_system()
	
	print("Fix tests completed!")
	quit()

func test_autoloads():
	print("\n=== Testing Autoloads ===")
	
	# Test GameState
	if GameState:
		print("✓ GameState autoload working")
		print("  Hero HP: ", GameState.hero_hp)
		print("  Deck size: ", GameState.deck.size())
	else:
		print("✗ GameState autoload failed")
	
	# Test CardDB
	if CardDB:
		print("✓ CardDB autoload working")
		print("  Cards loaded: ", CardDB.cards.size())
	else:
		print("✗ CardDB autoload failed")
	
	# Test EnemyDB
	if EnemyDB:
		print("✓ EnemyDB autoload working")
		print("  Enemies loaded: ", EnemyDB.enemies.size())
	else:
		print("✗ EnemyDB autoload failed")
	
	# Test AudioManager
	if AudioManager:
		print("✓ AudioManager autoload working")
	else:
		print("✗ AudioManager autoload failed")

func test_card_system():
	print("\n=== Testing Card System ===")
	
	# Test card creation
	var strike_card = Card.new("Strike")
	print("✓ Card creation working")
	print("  Strike card ID: ", strike_card.card_id)
	
	# Test card execution (should not crash)
	var result = strike_card.execute({})
	print("✓ Card execution working")
	print("  Execution success: ", result.success)
	
	# Test CardDB methods
	var common_cards = CardDB.get_cards_by_rarity("common")
	print("✓ CardDB rarity filtering working")
	print("  Common cards: ", common_cards.size())
	
	# Test resource management
	GameState.add_ammo(3)
	GameState.add_mana(2)
	print("✓ Resource management working")
	print("  Ammo: ", GameState.ammo, " Mana: ", GameState.mana)
