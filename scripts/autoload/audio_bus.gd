extends Node

#sound library
const SFX: Dictionary = {
	"click": preload("res://assets/audio/temp_sounds/click.mp3"),
	"wall_damage": preload("res://assets/audio/temp_sounds/hurt.wav"), 
	"shoot": preload("res://assets/audio/temp_sounds/eaglaxle-gun-shot-2-530789.mp3"),
	"spread_shot": preload("res://assets/audio/temp_sounds/shotgun-read-the-description.mp3"),
	"ricochet1": preload("res://assets/audio/temp_sounds/ricochet-1.mp3"),
	"ricochet2": preload("res://assets/audio/temp_sounds/ricochet-2.mp3"),
	"no_ammo": preload("res://assets/audio/temp_sounds/out-of-ammo-sfx.mp3"),
	"game_over": preload("res://assets/audio/temp_sounds/game_over_man.mp3"),
	"correct_word": preload("res://assets/audio/temp_sounds/coin.wav"),
	"thud": preload("res://assets/audio/temp_sounds/thud.mp3"),
	"music": preload("res://assets/audio/temp_sounds/BossSong.mp3")
}

var _active: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null

func play(audio_name: String, volume: float = 0.0):
	var sound: AudioStream = SFX.get(audio_name) as AudioStream
	if sound == null: return
	
	# Special handling for looping music
	if audio_name == "music":
		if _music_player and is_instance_valid(_music_player):
			_music_player.stop()
			_music_player.queue_free()
		
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = sound
		_music_player.volume_db = -10
		add_child(_music_player)
		
		# Enable looping
		if _music_player.stream.has_method("set_loop"):
			_music_player.stream.set_loop(true)
		else:
			_music_player.stream.loop = true
		
		_music_player.play()
		return
	
	# General player handling
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = volume
	if(audio_name == "click"):
		player.volume_db = -5.0
	if(audio_name == "correct_word"):
		player.volume_db = -20.0
	if(audio_name == "thud" or audio_name == "no_ammo" or audio_name == "spread_shot"):
		player.volume_db = -10.0
	add_child(player)
	_active.append(player)
	player.finished.connect(func():
		if is_instance_valid(player):
			_active.erase(player)
			player.queue_free()
	)
	player.play()

func clear_sounds():
	for player in _active:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active.clear()

func clear_music():
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.queue_free()
		_music_player = null
