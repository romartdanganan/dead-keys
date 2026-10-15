extends GutTest

# low wall pulse and ability ready glow, plus how the reduce flashing setting changes them

const HudWarningsScript := preload("res://scripts/missions/hud_warnings.gd")

var warnings: Node
var wall_bar: ProgressBar
var wall_panel: PanelContainer
var ability_panel: VBoxContainer
var _original_reduce: bool
var _original_charged: bool


func before_each() -> void:
	_original_reduce = SettingsState.reduce_flashing
	_original_charged = AbilityState.is_charged
	SettingsState.reduce_flashing = false
	AbilityState.is_charged = false
	wall_bar = ProgressBar.new()
	wall_bar.max_value = 100
	wall_bar.value = 100
	add_child_autofree(wall_bar)
	wall_panel = PanelContainer.new()
	add_child_autofree(wall_panel)
	ability_panel = VBoxContainer.new()
	add_child_autofree(ability_panel)
	warnings = HudWarningsScript.new()
	add_child_autofree(warnings)
	warnings.setup(wall_bar, wall_panel, ability_panel)


func after_each() -> void:
	SettingsState.reduce_flashing = _original_reduce
	AbilityState.is_charged = _original_charged


func test_wall_counts_as_low_at_a_quarter_health_or_less() -> void:
	assert_true(HudWarningsScript.is_wall_low(25, 100))
	assert_true(HudWarningsScript.is_wall_low(10, 100))
	assert_false(HudWarningsScript.is_wall_low(26, 100))


func test_healthy_wall_has_no_warning() -> void:
	await wait_physics_frames(3)
	assert_eq(wall_panel.modulate, Color.WHITE)


func test_low_wall_tints_the_wall_panel() -> void:
	wall_bar.value = 10
	SettingsState.reduce_flashing = true
	await wait_physics_frames(3)
	assert_eq(wall_panel.modulate, HudWarningsScript.WALL_WARNING_COLOUR)


func test_charged_ability_glows_until_used() -> void:
	SettingsState.reduce_flashing = true
	AbilityState.charged_changed.emit(true)
	await wait_physics_frames(3)
	assert_eq(ability_panel.modulate, HudWarningsScript.ABILITY_READY_COLOUR)

	AbilityState.charged_changed.emit(false)
	await wait_physics_frames(3)
	assert_eq(ability_panel.modulate, Color.WHITE)


func test_pulse_moves_between_normal_and_warning() -> void:
	var at_start := HudWarningsScript.warning_colour(Color.RED, 0.0, false)
	var later := HudWarningsScript.warning_colour(Color.RED, 0.25, false)
	assert_ne(at_start, later)


func test_reduce_flashing_holds_a_steady_colour() -> void:
	assert_eq(HudWarningsScript.warning_colour(Color.RED, 0.0, true), Color.RED)
	assert_eq(HudWarningsScript.warning_colour(Color.RED, 1.7, true), Color.RED)
