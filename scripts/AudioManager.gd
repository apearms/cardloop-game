extends Node

# Audio manager with background music and volume control

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_music: String = ""
var master_volume: float = 0.8  # Default 80%

# Music tracks
var music_tracks = {
	"menu": "res://audio/menu.wav",
	"game": "res://audio/game.wav",
	"boss": "res://audio/boss.wav",
	"victory": "res://audio/victory.wav",
	"defeat": "res://audio/defeat.wav"
}

func _ready():
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	# Create SFX players pool
	for i in range(5):
		var player = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		sfx_players.append(player)

	# Load saved volume
	_load_volume_setting()
	_apply_volume()

func _load_volume_setting():
	var file = FileAccess.open("user://volume.save", FileAccess.READ)
	if file:
		master_volume = file.get_float()
		file.close()
	else:
		master_volume = 0.8  # Default 80%

func _save_volume_setting():
	var file = FileAccess.open("user://volume.save", FileAccess.WRITE)
	if file:
		file.store_float(master_volume)
		file.close()

func set_volume(volume_percent: float):
	master_volume = clamp(volume_percent / 100.0, 0.0, 1.0)
	_apply_volume()
	_save_volume_setting()

func _apply_volume():
	var db_volume = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(0, db_volume)  # Master bus

func play_music(track_name: String):
	if current_music == track_name:
		return  # Already playing

	if music_tracks.has(track_name):
		var stream = load(music_tracks[track_name])
		if stream:
			music_player.stream = stream
			music_player.play()
			current_music = track_name

func stop_music():
	music_player.stop()
	current_music = ""

func play_sound(sound_name: String):
	print("🔊 Audio: ", sound_name)

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
	play_music("victory")

func play_defeat():
	play_music("defeat")
