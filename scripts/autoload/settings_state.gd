extends Node

# global settings state (#46): audio volumes and gameplay toggles reachable
# from the Settings menu, opened via Main Menu, Home Base, or Pause.
#
# Volumes apply live through Audio's bus API. mistake_system_enabled is read
# directly by MistakeSystem itself, since MistakeSystem lives inside each
# mission scene rather than as a singleton, same reason ProgressionManager
# exposes upgrade values for it to read in _apply_upgrades().

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var mistake_system_enabled: bool = true

# word-difficulty assist and typing-speed assist (GDD §2.8) are exposed in
# the Settings UI but not wired to any gameplay system yet, stored here so
# the toggle state isn't lost. Follow-up work, not part of #46.
var word_difficulty_assist: bool = false
var typing_speed_assist: bool = false


func _ready() -> void:
	load_settings()
	_apply_audio_volumes()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	Audio.set_bus_volume("Master", master_volume)
	save_settings()
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	Audio.set_bus_volume("Music", music_volume)
	save_settings()
	settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	Audio.set_bus_volume("SFX", sfx_volume)
	save_settings()
	settings_changed.emit()


func set_mistake_system_enabled(value: bool) -> void:
	mistake_system_enabled = value
	save_settings()
	settings_changed.emit()


func set_word_difficulty_assist(value: bool) -> void:
	word_difficulty_assist = value
	save_settings()
	settings_changed.emit()


func set_typing_speed_assist(value: bool) -> void:
	typing_speed_assist = value
	save_settings()
	settings_changed.emit()


func _apply_audio_volumes() -> void:
	Audio.set_bus_volume("Master", master_volume)
	Audio.set_bus_volume("Music", music_volume)
	Audio.set_bus_volume("SFX", sfx_volume)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "mistake_system_enabled", mistake_system_enabled)
	config.set_value("settings", "word_difficulty_assist", word_difficulty_assist)
	config.set_value("settings", "typing_speed_assist", typing_speed_assist)
	config.save(SAVE_PATH)


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return # first launch, no save file yet, keep defaults

	master_volume = config.get_value("settings", "master_volume", master_volume)
	music_volume = config.get_value("settings", "music_volume", music_volume)
	sfx_volume = config.get_value("settings", "sfx_volume", sfx_volume)
	mistake_system_enabled = config.get_value("settings", "mistake_system_enabled", mistake_system_enabled)
	word_difficulty_assist = config.get_value("settings", "word_difficulty_assist", word_difficulty_assist)
	typing_speed_assist = config.get_value("settings", "typing_speed_assist", typing_speed_assist)
