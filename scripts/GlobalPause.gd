extends Node
var is_paused := false

func toggle_pause():
	if get_tree().current_scene.name == "TitleScreen":
		get_tree().quit()   # ESC on title quits
		return

	is_paused = !is_paused
	get_tree().paused = is_paused

	# Show/hide pause menu in current scene
	var current_scene = get_tree().current_scene
	if current_scene.has_method("_toggle_pause_menu"):
		current_scene._toggle_pause_menu()
