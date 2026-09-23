extends Node

# global settings state: audio volumes, gameplay toggles and display options
# for the Settings menu, opened via Main Menu, Home Base, or Pause.
# MistakeSystem reads mistake_system_enabled directly since it lives per mission.

signal settings_changed

const SAVE_PATH := "user://settings.cfg"

# windowed resolutions offered in the Display tab, index 0 matches project.godot
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var mistake_system_enabled: bool = true
var fullscreen: bool = false
var resolution_index: int = 0


func _ready() -> void:
	load_settings()
	_apply_audio_volumes()

	# skip on default settings so a fresh launch keeps the project's own window
	if fullscreen or resolution_index != 0:
		_apply_display()


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


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_display()
	save_settings()
	settings_changed.emit()


func set_resolution_index(index: int) -> void:
	resolution_index = clampi(index, 0, RESOLUTIONS.size() - 1)
	_apply_display()
	save_settings()
	settings_changed.emit()


func _apply_audio_volumes() -> void:
	Audio.set_bus_volume("Master", master_volume)
	Audio.set_bus_volume("Music", music_volume)
	Audio.set_bus_volume("SFX", sfx_volume)


func _apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return

	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var window_size: Vector2i = RESOLUTIONS[resolution_index]
	DisplayServer.window_set_size(window_size)

	# recentre the resized window on the screen it's currently on
	var screen_rect := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	# whole-pixel positions, so dropping the remainder is intended
	@warning_ignore("integer_division")
	DisplayServer.window_set_position(screen_rect.position + (screen_rect.size - window_size) / 2)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "mistake_system_enabled", mistake_system_enabled)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "resolution_index", resolution_index)
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
	fullscreen = config.get_value("settings", "fullscreen", fullscreen)

	# clamp in case RESOLUTIONS shrinks after a save was written
	var saved_index: int = config.get_value("settings", "resolution_index", resolution_index)
	resolution_index = clampi(saved_index, 0, RESOLUTIONS.size() - 1)
