extends Node

# Grid management for battle system - tracks tile occupancy
# Plain script helper, no scene required

const GRID_W := 6
const GRID_H := 3

var occupancy := Array() # 2D bool array [lane][column]

func _ready():
	clear()

func clear():
	occupancy = []
	for lane in range(GRID_H):
		occupancy.append([])
		for col in range(GRID_W):
			occupancy[lane].append(false)

func is_free(lane: int, col: int) -> bool:
	if lane < 0 or lane >= GRID_H or col < 0 or col >= GRID_W:
		return false
	return not occupancy[lane][col]

func take_cell(lane: int, col: int):
	if lane >= 0 and lane < GRID_H and col >= 0 and col < GRID_W:
		occupancy[lane][col] = true

func release_cell(lane: int, col: int):
	if lane >= 0 and lane < GRID_H and col >= 0 and col < GRID_W:
		occupancy[lane][col] = false

# Helper function to find next free lane starting from given lane
func find_free_lane(start_lane: int, col: int) -> int:
	# Try downward first
	for lane in range(start_lane, GRID_H):
		if is_free(lane, col):
			return lane
	
	# Try upward
	for lane in range(start_lane - 1, -1, -1):
		if is_free(lane, col):
			return lane
	
	return -1 # No free lane found
