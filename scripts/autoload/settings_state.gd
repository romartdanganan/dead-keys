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
# accessibility: swaps flashing and pulsing feedback for steady tints (GDD 2.8, 7)
var reduce_flashing: bool = false
var fullscreen: bool = false
var resolution_index: int = 0

# default physical keycodes for the three supply slots
const DEFAULT_SUPPLY_KEYS: Array[int] = [KEY_1, KEY_2, KEY_3]

# fire defaults to left click (mouse button 1)
const DEFAULT_FIRE_BUTTON := MOUSE_BUTTON_LEFT


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


func set_reduce_flashing(value: bool) -> void:
	reduce_flashing = value
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


# replaces the binding for call_supply_N with the given physical keycode.
# returns false if keycode is already used by another supply slot or fire.
func set_supply_key(slot_index: int, keycode: int) -> bool:
	for i in 3:
		if i != slot_index and get_supply_key(i) == keycode:
			return false
	if _fire_is_key() and get_fire_keycode() == keycode:
		return false
	var action := "call_supply_%d" % (slot_index + 1)
	InputMap.action_erase_events(action)
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	InputMap.action_add_event(action, event)
	save_settings()
	settings_changed.emit()
	return true


# returns the current physical keycode for a supply slot
func get_supply_key(slot_index: int) -> int:
	var action := "call_supply_%d" % (slot_index + 1)
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return ev.physical_keycode
	return DEFAULT_SUPPLY_KEYS[slot_index]


# replaces fire with a key. returns false if keycode conflicts with a supply slot.
func set_fire_key(keycode: int) -> bool:
	for i in 3:
		if get_supply_key(i) == keycode:
			return false
	InputMap.action_erase_events("fire")
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	InputMap.action_add_event("fire", event)
	save_settings()
	settings_changed.emit()
	return true


# replaces fire with a mouse button.
func set_fire_mouse_button(button_index: MouseButton) -> void:
	InputMap.action_erase_events("fire")
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event("fire", event)
	save_settings()
	settings_changed.emit()


# true if the current fire binding is a key rather than a mouse button
func _fire_is_key() -> bool:
	for ev in InputMap.action_get_events("fire"):
		if ev is InputEventKey:
			return true
	return false


# returns the physical keycode if fire is bound to a key, else -1
func get_fire_keycode() -> int:
	for ev in InputMap.action_get_events("fire"):
		if ev is InputEventKey:
			return ev.physical_keycode
	return -1


# human-readable label for the current fire binding
func get_fire_label() -> String:
	for ev in InputMap.action_get_events("fire"):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
		if ev is InputEventMouseButton:
			match ev.button_index:
				MOUSE_BUTTON_LEFT:   return "Left Click"
				MOUSE_BUTTON_RIGHT:  return "Right Click"
				MOUSE_BUTTON_MIDDLE: return "Middle Click"
				_: return "Mouse %d" % (ev.button_index as int)
	return "Left Click"


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
	config.set_value("settings", "reduce_flashing", reduce_flashing)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "resolution_index", resolution_index)
	for i in 3:
		config.set_value("settings", "supply_key_%d" % i, get_supply_key(i))
	# fire: store type ("key" or "mouse") plus the code
	if _fire_is_key():
		config.set_value("settings", "fire_type", "key")
		config.set_value("settings", "fire_code", get_fire_keycode())
	else:
		config.set_value("settings", "fire_type", "mouse")
		var mb: MouseButton = MOUSE_BUTTON_LEFT
		for ev in InputMap.action_get_events("fire"):
			if ev is InputEventMouseButton:
				mb = ev.button_index
		config.set_value("settings", "fire_code", mb as int)
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
	reduce_flashing = config.get_value("settings", "reduce_flashing", reduce_flashing)
	fullscreen = config.get_value("settings", "fullscreen", fullscreen)

	var saved_index: int = config.get_value("settings", "resolution_index", resolution_index)
	resolution_index = clampi(saved_index, 0, RESOLUTIONS.size() - 1)

	for i in 3:
		var keycode: int = config.get_value("settings", "supply_key_%d" % i, DEFAULT_SUPPLY_KEYS[i])
		set_supply_key(i, keycode)

	var fire_type: String = config.get_value("settings", "fire_type", "mouse")
	var fire_code: int = config.get_value("settings", "fire_code", MOUSE_BUTTON_LEFT as int)
	if fire_type == "key":
		set_fire_key(fire_code)
	else:
		set_fire_mouse_button(fire_code as MouseButton)
