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
	"pause": preload("res://assets/audio/temp_sounds/pause.mp3"),
	"resume": preload("res://assets/audio/temp_sounds/resume.mp3"),
	
	"game_over": preload("res://assets/audio/temp_sounds/game_over_man.mp3"),
	"play_music": preload("res://assets/audio/temp_sounds/BossSong.mp3"),
	"main_music": preload("res://assets/audio/temp_sounds/grimsong.mp3")
}

var _active: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer = null


func _ready() -> void:
	# autoloads default to PROCESS_MODE_PAUSABLE, meaning Audio (and any sound
	# player added under it) would go silent the instant get_tree().paused
	# becomes true. Without this, the "pause" sound cuts off immediately since
	# it plays right before the pause flag flips.
	process_mode = Node.PROCESS_MODE_ALWAYS

func play(audio_name: String, volume: float = 0.0) -> void:
	var sound: AudioStream = SFX.get(audio_name) as AudioStream
	if sound == null: return
	
	# Special handling for looping music. Godot's per-asset "loop" checkbox
	# lives in the .import file, which is gitignored (*.import) and never
	# committed, so it can't be relied on across machines. Set it in code
	# instead so looping works the same for everyone on a fresh checkout.
	if audio_name == "main_music" or audio_name == "play_music" :
		if _music_player and is_instance_valid(_music_player):
			return
		
		if sound is AudioStreamMP3 or sound is AudioStreamOggVorbis:
			sound.loop = true
		elif sound is AudioStreamWAV:
			sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
		
		_music_player = AudioStreamPlayer.new()
		_music_player.stream = sound
		_music_player.volume_db = -5
		add_child(_music_player)
		
		_music_player.play()
		return
	
	# General player handling
	var player := AudioStreamPlayer.new()
	player.stream = sound
	player.volume_db = volume
	
	# audio volume editing. NOTE: these override whatever volume the caller
	# passed in for these specific sounds — the volume parameter has no
	# effect on the 8 names listed below, only on anything not in this list
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

func clear_sounds() -> void:
	for player in _active:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_active.clear()

func clear_music() -> void:
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.queue_free()
		_music_player = null
