extends Node

#sound library
const SFX: Dictionary = {
	"click": preload("res://assets/audio/temp_sounds/click.mp3"),
	"thud": preload("res://assets/audio/temp_sounds/thud.mp3"),
	"shoot": preload("res://assets/audio/temp_sounds/eaglaxle-gun-shot-2-530789.mp3"),
	"hit_zombie": preload("res://assets/audio/temp_sounds/Zombie_hurt1.ogg"),
	"no_ammo": preload("res://assets/audio/temp_sounds/out-of-ammo-sfx.mp3"),
	"add_ammo": preload("res://assets/audio/temp_sounds/reload.MP3"),
	"jammed": preload("res://assets/audio/temp_sounds/gunjam.MP3"),
	"ability_unlock": preload("res://assets/audio/temp_sounds/heal.mp3"),
	"spread_shot": preload("res://assets/audio/temp_sounds/shotgun-read-the-description.mp3"),
	"ricochet": preload("res://assets/audio/temp_sounds/ricochet.MP3"),
	"wall_damage": preload("res://assets/audio/temp_sounds/hurt.wav"), 
	"correct_keystroke": preload("res://assets/audio/temp_sounds/coin.wav"),
	"wrong_keystroke": preload("res://assets/audio/temp_sounds/freesound_community-wrong-47985.mp3"),
	
	"game_over": preload("res://assets/audio/temp_sounds/game_over_man.mp3"),
	"play_music": preload("res://assets/audio/temp_sounds/BossSong.mp3"),
	"main_music": preload("res://assets/audio/temp_sounds/grimsong.mp3")
}

var _active: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null

func play(audio_name: String, volume: float = 0.0):
	var sound: AudioStream = SFX.get(audio_name) as AudioStream
	if sound == null: return
	
	# Special handling for looping music
	if audio_name == "main_music" or audio_name == "play_music" :
		if _music_player and is_instance_valid(_music_player):
			_music_player.stop()
			_music_player.queue_free()
		
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = sound
		_music_player.volume_db = -5
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
	
	# audio volume editing
	if (audio_name == "spread_shot"
	or audio_name == "correct_keystroke"):
		player.volume_db = -15.0
	
	if (audio_name == "thud" 
	or audio_name == "no_ammo" 
	or audio_name == "hit_zombie"
	or audio_name == "wrong_keystroke"):
		player.volume_db = -10.0
	
	if (audio_name == "click" 
	or audio_name == "wall_damage"):
		player.volume_db = -5.0
	
	if (audio_name == "add_ammo"):
		player.volume_db = 10.0
	
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
