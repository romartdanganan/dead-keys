extends GutTest

# fire, ability and supply bindings can never share a key or mouse button

const TEST_SAVE_PATH := "user://test_settings_bindings.cfg"
const ACTIONS: Array[String] = ["fire", "use_ability", "call_supply_1", "call_supply_2", "call_supply_3"]

var _saved_path: String
var _saved_events: Dictionary = {}


func before_each() -> void:
	_saved_path = SettingsState.save_path
	SettingsState.save_path = TEST_SAVE_PATH
	for action in ACTIONS:
		_saved_events[action] = InputMap.action_get_events(action)
	_set_mouse("fire", MOUSE_BUTTON_LEFT)
	_set_mouse("use_ability", MOUSE_BUTTON_RIGHT)
	_set_key("call_supply_1", KEY_1)
	_set_key("call_supply_2", KEY_2)
	_set_key("call_supply_3", KEY_3)


func after_each() -> void:
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		for event in _saved_events[action]:
			InputMap.action_add_event(action, event)
	SettingsState.save_path = _saved_path
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


# sets a binding directly, skipping the duplicate guard, for test setup only
func _set_mouse(action: String, button: MouseButton) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


func _set_key(action: String, keycode: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, event)


func test_ability_defaults_to_right_click() -> void:
	assert_eq(SettingsState.get_ability_label(), "Right Click")


func test_ability_cannot_take_the_fire_button() -> void:
	assert_false(SettingsState.set_ability_mouse_button(MOUSE_BUTTON_LEFT))
	assert_eq(SettingsState.get_ability_label(), "Right Click")


func test_fire_cannot_take_the_ability_button() -> void:
	assert_false(SettingsState.set_fire_mouse_button(MOUSE_BUTTON_RIGHT))
	assert_eq(SettingsState.get_fire_label(), "Left Click")


func test_ability_cannot_take_a_supply_key() -> void:
	assert_false(SettingsState.set_ability_key(KEY_2))


func test_supply_cannot_take_the_ability_key() -> void:
	assert_true(SettingsState.set_ability_key(KEY_SPACE))
	assert_false(SettingsState.set_supply_key(0, KEY_SPACE))


func test_ability_can_move_to_a_free_button() -> void:
	assert_true(SettingsState.set_ability_mouse_button(MOUSE_BUTTON_MIDDLE))
	assert_eq(SettingsState.get_ability_label(), "Middle Click")


func test_ability_binding_survives_save_and_load() -> void:
	SettingsState.set_ability_key(KEY_SPACE)
	_set_mouse("use_ability", MOUSE_BUTTON_RIGHT)
	SettingsState.load_settings()
	assert_eq(SettingsState.get_ability_label(), OS.get_keycode_string(KEY_SPACE))


# saves from before the ability existed may already have fire on right click
func test_old_save_with_fire_on_right_click_moves_the_ability() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "fire_type", "mouse")
	config.set_value("settings", "fire_code", MOUSE_BUTTON_RIGHT as int)
	config.save(TEST_SAVE_PATH)
	SettingsState.load_settings()
	assert_eq(SettingsState.get_fire_label(), "Right Click")
	assert_ne(SettingsState.get_ability_label(), "Right Click")


func test_swapped_supply_keys_load_correctly() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "supply_key_0", KEY_2 as int)
	config.set_value("settings", "supply_key_1", KEY_1 as int)
	config.set_value("settings", "supply_key_2", KEY_3 as int)
	config.save(TEST_SAVE_PATH)
	SettingsState.load_settings()
	assert_eq(SettingsState.get_supply_key(0), KEY_2 as int)
	assert_eq(SettingsState.get_supply_key(1), KEY_1 as int)
