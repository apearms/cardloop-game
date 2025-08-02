extends Node

# Test script for Tasks 1-3 implementation

func _ready():
	print("=== Testing Tasks 1-3 Implementation ===")
	
	# Test 1: GridManager
	print("\n1. Testing GridManager:")
	test_grid_manager()
	
	# Test 2: ArtifactDB
	print("\n2. Testing ArtifactDB:")
	test_artifact_db()
	
	# Test 3: GameState artifacts
	print("\n3. Testing GameState artifacts:")
	test_game_state_artifacts()
	
	print("\n=== All tests completed ===")

func test_grid_manager():
	GridManager.clear()
	print("  - Grid cleared")
	
	# Test occupancy
	print("  - Cell (1,2) free:", GridManager.is_free(1, 2))
	GridManager.take_cell(1, 2)
	print("  - Cell (1,2) after taking:", GridManager.is_free(1, 2))
	GridManager.release_cell(1, 2)
	print("  - Cell (1,2) after releasing:", GridManager.is_free(1, 2))
	
	# Test find_free_lane
	GridManager.take_cell(0, 5)
	GridManager.take_cell(1, 5)
	var free_lane = GridManager.find_free_lane(0, 5)
	print("  - Free lane when 0,1 blocked at col 5:", free_lane)

func test_artifact_db():
	var loop6 = ArtifactDB.get_artifact("Loop-6")
	print("  - Loop-6 pattern:", loop6.get("slot_pattern", []))
	print("  - Loop-6 desc:", loop6.get("desc", ""))
	
	var loop4x2 = ArtifactDB.get_artifact("Loop-4x2")
	print("  - Loop-4x2 pattern:", loop4x2.get("slot_pattern", []))

func test_game_state_artifacts():
	GameState.reset_game()
	print("  - Current artifacts:", GameState.artifacts)
	print("  - Current slot pattern:", GameState.current_slot_pattern())
	print("  - Max deck size:", GameState.max_deck_size())
	print("  - Current deck size:", GameState.deck.size())
	print("  - Can add card:", GameState.can_add_card())
