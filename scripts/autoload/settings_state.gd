extends Node

# global settings state: audio volumes, gameplay toggles and display options
# for the Settings menu, opened via Main Menu, Home Base, or Pause.
# MistakeSystem reads mistake_system_enabled directly since it lives per mission.

signal settings_changed

# a var so GUT can point it at a throwaway file instead of the real settings
var save_path := "user://settings.cfg"

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

# accessibility tab for slower typists, index 0 is normal zombie speed
const ZOMBIE_SPEED_MULTIPLIERS: Array[float] = [1.0, 0.85, 0.7, 0.55]
const CRATE_TIMER_MULTIPLIER: float = 1.5
const WORD_FONT_SIZE: int = 22
const LARGE_WORD_FONT_SIZE: int = 30

var zombie_speed_index: int = 0
var longer_crate_timer: bool = false
var large_word_text: bool = false
var hold_to_fire: bool = false

# default physical keycodes for the three supply slots
const DEFAULT_SUPPLY_KEYS: Array[int] = [KEY_1, KEY_2, KEY_3]

# fire defaults to left click (mouse button 1)
const DEFAULT_FIRE_BUTTON := MOUSE_BUTTON_LEFT
# the ability defaults to right click so both shots sit on the mouse
const DEFAULT_ABILITY_BUTTON := MOUSE_BUTTON_RIGHT

# actions that accept a key or a mouse button, supply slots take keys only
const POINTER_ACTIONS: Array[String] = ["fire", "use_ability"]
const SUPPLY_ACTIONS: Array[String] = ["call_supply_1", "call_supply_2", "call_supply_3"]

# stops every rebind during load_settings() from re-saving a half loaded file
var _is_loading: bool = false


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


# each accessibility setter saves straight away and tells open menus to refresh
func set_zombie_speed_index(index: int) -> void:
	zombie_speed_index = clampi(index, 0, ZOMBIE_SPEED_MULTIPLIERS.size() - 1)
	save_settings()
	settings_changed.emit()


# zombie.gd multiplies its movement speed by this every frame
func get_zombie_speed_multiplier() -> float:
	return ZOMBIE_SPEED_MULTIPLIERS[clampi(zombie_speed_index, 0, ZOMBIE_SPEED_MULTIPLIERS.size() - 1)]


func set_longer_crate_timer(value: bool) -> void:
	longer_crate_timer = value
	save_settings()
	settings_changed.emit()


# supply crates multiply their 8 second timer by this when they land
func get_crate_timer_multiplier() -> float:
	return CRATE_TIMER_MULTIPLIER if longer_crate_timer else 1.0


func set_large_word_text(value: bool) -> void:
	large_word_text = value
	save_settings()
	settings_changed.emit()


# font size for the words above zombies and crates
func get_word_font_size() -> int:
	return LARGE_WORD_FONT_SIZE if large_word_text else WORD_FONT_SIZE


# mission_1.gd keeps firing while the fire button is held when this is on
func set_hold_to_fire(value: bool) -> void:
	hold_to_fire = value
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
# returns false if keycode is already used by another supply slot, fire or the ability.
func set_supply_key(slot_index: int, keycode: int) -> bool:
	return _bind_key(SUPPLY_ACTIONS[slot_index], keycode)


# returns the current physical keycode for a supply slot
func get_supply_key(slot_index: int) -> int:
	var keycode := _action_keycode(SUPPLY_ACTIONS[slot_index])
	return keycode if keycode != -1 else DEFAULT_SUPPLY_KEYS[slot_index]


# replaces fire with a key. returns false if keycode is already bound elsewhere.
func set_fire_key(keycode: int) -> bool:
	return _bind_key("fire", keycode)


# replaces fire with a mouse button. returns false if the ability already uses it.
func set_fire_mouse_button(button_index: MouseButton) -> bool:
	return _bind_mouse("fire", button_index)


# returns the physical keycode if fire is bound to a key, else -1
func get_fire_keycode() -> int:
	return _action_keycode("fire")


# human-readable label for the current fire binding
func get_fire_label() -> String:
	return get_binding_label("fire")


func set_ability_key(keycode: int) -> bool:
	return _bind_key("use_ability", keycode)


func set_ability_mouse_button(button_index: MouseButton) -> bool:
	return _bind_mouse("use_ability", button_index)


func get_ability_label() -> String:
	return get_binding_label("use_ability")


func get_binding_label(action: String) -> String:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
		if ev is InputEventMouseButton:
			match ev.button_index:
				MOUSE_BUTTON_LEFT:   return "Left Click"
				MOUSE_BUTTON_RIGHT:  return "Right Click"
				MOUSE_BUTTON_MIDDLE: return "Middle Click"
				_: return "Mouse %d" % (ev.button_index as int)
	return "Unbound"


# true if any other supply, fire or ability binding already uses this key
func is_key_taken(keycode: int, except_action: String) -> bool:
	for action in SUPPLY_ACTIONS + POINTER_ACTIONS:
		if action != except_action and _action_keycode(action) == keycode:
			return true
	return false


func is_mouse_button_taken(button_index: int, except_action: String) -> bool:
	for action in POINTER_ACTIONS:
		if action != except_action and _action_mouse_button(action) == button_index:
			return true
	return false


func _bind_key(action: String, keycode: int) -> bool:
	if is_key_taken(keycode, action):
		return false
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	_replace_binding(action, event)
	return true


func _bind_mouse(action: String, button_index: int) -> bool:
	if is_mouse_button_taken(button_index, action):
		return false
	var event := InputEventMouseButton.new()
	event.button_index = button_index as MouseButton
	_replace_binding(action, event)
	return true


func _replace_binding(action: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)
	if not _is_loading:
		save_settings()
	settings_changed.emit()


# physical keycode if the action is bound to a key, else -1
func _action_keycode(action: String) -> int:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			return ev.physical_keycode
	return -1


# mouse button index if the action is bound to a mouse button, else -1
func _action_mouse_button(action: String) -> int:
	for ev in InputMap.action_get_events(action):
		if ev is InputEventMouseButton:
			return ev.button_index
	return -1


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
	# accessibility tab options
	config.set_value("settings", "zombie_speed_index", zombie_speed_index)
	config.set_value("settings", "longer_crate_timer", longer_crate_timer)
	config.set_value("settings", "large_word_text", large_word_text)
	config.set_value("settings", "hold_to_fire", hold_to_fire)
	for i in 3:
		config.set_value("settings", "supply_key_%d" % i, get_supply_key(i))
	_save_pointer_binding(config, "fire", "fire", DEFAULT_FIRE_BUTTON)
	_save_pointer_binding(config, "use_ability", "ability", DEFAULT_ABILITY_BUTTON)
	config.save(save_path)


# stores "key" or "mouse" plus the code under prefix_type and prefix_code
func _save_pointer_binding(config: ConfigFile, action: String, prefix: String, default_button: MouseButton) -> void:
	var keycode := _action_keycode(action)
	if keycode != -1:
		config.set_value("settings", prefix + "_type", "key")
		config.set_value("settings", prefix + "_code", keycode)
		return
	var button := _action_mouse_button(action)
	config.set_value("settings", prefix + "_type", "mouse")
	if button == -1:
		button = default_button
	config.set_value("settings", prefix + "_code", button)


func _load_pointer_binding(config: ConfigFile, action: String, prefix: String, default_button: MouseButton) -> void:
	var binding_type: String = config.get_value("settings", prefix + "_type", "mouse")
	var code: int = config.get_value("settings", prefix + "_code", default_button as int)
	var ok: bool = _bind_key(action, code) if binding_type == "key" else _bind_mouse(action, code)
	if ok:
		return
	# an older save can clash with a newer default, so fall back to a free mouse button
	for button in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_LEFT]:
		if _bind_mouse(action, button):
			return


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(save_path)
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

	# accessibility tab options, the speed index is clamped in case the list changes
	var saved_speed: int = config.get_value("settings", "zombie_speed_index", zombie_speed_index)
	zombie_speed_index = clampi(saved_speed, 0, ZOMBIE_SPEED_MULTIPLIERS.size() - 1)
	longer_crate_timer = config.get_value("settings", "longer_crate_timer", longer_crate_timer)
	large_word_text = config.get_value("settings", "large_word_text", large_word_text)
	hold_to_fire = config.get_value("settings", "hold_to_fire", hold_to_fire)

	_is_loading = true
	# cleared first so swapped keys (slot 1 on 2, slot 2 on 1) don't clash with the defaults
	for action in SUPPLY_ACTIONS:
		InputMap.action_erase_events(action)
	for i in 3:
		var keycode: int = config.get_value("settings", "supply_key_%d" % i, DEFAULT_SUPPLY_KEYS[i])
		set_supply_key(i, keycode)

	# the ability is cleared first so a save from before it existed can keep
	# right click on fire, the ability then falls back to another button
	InputMap.action_erase_events("use_ability")
	_load_pointer_binding(config, "fire", "fire", DEFAULT_FIRE_BUTTON)
	_load_pointer_binding(config, "use_ability", "ability", DEFAULT_ABILITY_BUTTON)
	_is_loading = false
