extends GutTest

# accessibility tab: zombie speed, longer crate timer, large word text and hold to fire

const TEST_SAVE_PATH := "user://test_accessibility_settings.cfg"
const ACTIONS: Array[String] = ["fire", "use_ability", "call_supply_1", "call_supply_2", "call_supply_3"]
const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const CrateScene := preload("res://scenes/entities/supply_crate.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const WordLabelStyle := preload("res://scripts/ui/word_label_style.gd")

var _saved_path: String
var _saved_events: Dictionary = {}
var _saved_values: Dictionary = {}


func before_each() -> void:
	_saved_path = SettingsState.save_path
	SettingsState.save_path = TEST_SAVE_PATH
	for action in ACTIONS:
		_saved_events[action] = InputMap.action_get_events(action)
	_saved_values = {
		"zombie_speed_index": SettingsState.zombie_speed_index,
		"longer_crate_timer": SettingsState.longer_crate_timer,
		"large_word_text": SettingsState.large_word_text,
		"hold_to_fire": SettingsState.hold_to_fire,
		"reduce_screen_shake": SettingsState.reduce_screen_shake,
	}
	SettingsState.zombie_speed_index = 0
	SettingsState.longer_crate_timer = false
	SettingsState.large_word_text = false
	SettingsState.hold_to_fire = false
	SettingsState.reduce_screen_shake = false


func after_each() -> void:
	for key in _saved_values:
		SettingsState.set(key, _saved_values[key])
	for action in ACTIONS:
		InputMap.action_erase_events(action)
		for event in _saved_events[action]:
			InputMap.action_add_event(action, event)
	SettingsState.save_path = _saved_path
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func _spawn_zombie() -> Zombie:
	# wall far away so the zombie never reaches it
	var wall := Node2D.new()
	wall.global_position = Vector2(5000, 0)
	add_child_autofree(wall)
	var zombie: Zombie = ZombieScene.instantiate()
	zombie.is_pooled = true
	add_child_autofree(zombie)
	zombie.setup(WALKER_TYPE, wall)
	return zombie


func _make_label() -> RichTextLabel:
	var label := RichTextLabel.new()
	label.offset_left = -110.0
	label.offset_top = -72.0
	label.offset_right = 110.0
	label.offset_bottom = -37.0
	add_child_autofree(label)
	return label


func test_default_zombie_speed_is_normal() -> void:
	assert_eq(SettingsState.get_zombie_speed_multiplier(), 1.0)


func test_zombie_speed_options_only_ever_slow_zombies_down() -> void:
	var previous := 1.0
	for multiplier in SettingsState.ZOMBIE_SPEED_MULTIPLIERS.slice(1):
		assert_lt(multiplier, previous)
		previous = multiplier


func test_zombie_speed_index_is_clamped() -> void:
	SettingsState.set_zombie_speed_index(99)
	assert_eq(SettingsState.zombie_speed_index, SettingsState.ZOMBIE_SPEED_MULTIPLIERS.size() - 1)
	SettingsState.set_zombie_speed_index(-3)
	assert_eq(SettingsState.zombie_speed_index, 0)


func test_slower_setting_scales_zombie_movement_speed() -> void:
	var zombie := _spawn_zombie()
	var normal_speed := zombie.get_movement_speed()
	SettingsState.set_zombie_speed_index(2)
	assert_almost_eq(zombie.get_movement_speed(), normal_speed * SettingsState.ZOMBIE_SPEED_MULTIPLIERS[2], 0.001)


func test_crate_uses_normal_timer_by_default() -> void:
	var crate: SupplyCrate = CrateScene.instantiate()
	add_child_autofree(crate)
	assert_almost_eq(crate.expiry_timer.wait_time, SupplyCrate.EXPIRY_SECONDS, 0.001)


func test_longer_crate_timer_stretches_the_claim_window() -> void:
	SettingsState.set_longer_crate_timer(true)
	var crate: SupplyCrate = CrateScene.instantiate()
	add_child_autofree(crate)
	var expected := SupplyCrate.EXPIRY_SECONDS * SettingsState.CRATE_TIMER_MULTIPLIER
	assert_almost_eq(crate.expiry_timer.wait_time, expected, 0.001)
	assert_almost_eq(crate.time_bar.max_value, expected, 0.001)


func test_normal_word_text_keeps_the_scene_layout() -> void:
	var label := _make_label()
	WordLabelStyle.apply(label)
	assert_eq(label.get_theme_font_size("normal_font_size"), SettingsState.WORD_FONT_SIZE)
	assert_eq(label.offset_top, -72.0)
	assert_eq(label.offset_left, -110.0)
	assert_eq(label.offset_right, 110.0)


func test_large_word_text_grows_up_and_wider_from_the_same_bottom_edge() -> void:
	SettingsState.set_large_word_text(true)
	var label := _make_label()
	WordLabelStyle.apply(label)
	assert_eq(label.get_theme_font_size("normal_font_size"), SettingsState.LARGE_WORD_FONT_SIZE)
	assert_eq(label.offset_bottom, -37.0)
	assert_lt(label.offset_top, -72.0)
	assert_gt(label.offset_right - label.offset_left, 220.0)


func test_word_label_style_can_be_reapplied_to_a_pooled_label() -> void:
	SettingsState.set_large_word_text(true)
	var label := _make_label()
	WordLabelStyle.apply(label)
	var first := [label.offset_left, label.offset_top, label.offset_right, label.offset_bottom]
	WordLabelStyle.apply(label)
	assert_eq([label.offset_left, label.offset_top, label.offset_right, label.offset_bottom], first)


func test_accessibility_settings_survive_save_and_load() -> void:
	SettingsState.set_zombie_speed_index(3)
	SettingsState.set_longer_crate_timer(true)
	SettingsState.set_large_word_text(true)
	SettingsState.set_hold_to_fire(true)

	SettingsState.zombie_speed_index = 0
	SettingsState.longer_crate_timer = false
	SettingsState.large_word_text = false
	SettingsState.hold_to_fire = false
	SettingsState.load_settings()

	assert_eq(SettingsState.zombie_speed_index, 3)
	assert_true(SettingsState.longer_crate_timer)
	assert_true(SettingsState.large_word_text)
	assert_true(SettingsState.hold_to_fire)


func test_reduce_screen_shake_survives_save_and_load() -> void:
	SettingsState.set_reduce_screen_shake(true)
	SettingsState.reduce_screen_shake = false
	SettingsState.load_settings()
	assert_true(SettingsState.reduce_screen_shake)
