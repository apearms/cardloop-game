extends Node

# Simple audio manager for game sounds

var audio_players: Array[AudioStreamPlayer] = []

func _ready():
	# Create audio players for different sound types
	for i in range(5):  # Pool of 5 audio players
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)

func play_sound(sound_name: String):
	# Simple placeholder audio system - just print to console
	# In a real game, you would load actual audio files here
	print("🔊 Audio: ", sound_name)

# Simplified audio system - no actual audio files needed

# Sound effect functions
func play_card_use():
	play_sound("card_use")

func play_enemy_hit():
	play_sound("enemy_hit")

func play_enemy_death():
	play_sound("enemy_death")

func play_hero_damage():
	play_sound("hero_damage")

func play_button_click():
	play_sound("button_click")

func play_victory():
	play_sound("victory")

func play_defeat():
	play_sound("defeat")
