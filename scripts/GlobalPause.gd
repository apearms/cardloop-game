extends Node

var pause_menu_visible: bool = false
var current_pause_menu: Control = null

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if pause_menu_visible:
			# Hide menu and unpause
			if current_pause_menu:
				current_pause_menu.hide_pause_menu()
			_unpause()
		else:
			# Show menu and pause
			if current_pause_menu:
				current_pause_menu.show_pause_menu()
			_pause()

func _pause():
	get_tree().paused = true
	pause_menu_visible = true

func _unpause():
	get_tree().paused = false
	pause_menu_visible = false

func register_pause_menu(menu: Control):
	current_pause_menu = menu

func unregister_pause_menu():
	current_pause_menu = null
