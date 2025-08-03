extends Node
var is_paused := false

func toggle_pause():
	# Early return when on TitleScreen
	if get_tree().current_scene.name == "TitleScreen":
		return

	is_paused = !is_paused
	get_tree().paused = is_paused
