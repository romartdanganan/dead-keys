extends GutTest

# mission camera shake and the reduce screen shake setting

const ScreenShake := preload("res://scripts/missions/screen_shake.gd")
const MISSION_1_SCENE := preload("res://scenes/missions/mission_1.tscn")
const HOME := Vector2(640, 360)

var camera: Camera2D
var _saved_reduce: bool


func before_each() -> void:
	_saved_reduce = SettingsState.reduce_screen_shake
	SettingsState.reduce_screen_shake = false
	camera = ScreenShake.new()
	# placed like the Camera node in mission_1.tscn
	camera.position = HOME
	add_child_autofree(camera)


func after_each() -> void:
	SettingsState.reduce_screen_shake = _saved_reduce


# reads a node's saved property straight from the scene file without running the mission
func _mission_scene_value(node_name: String, property: String) -> Variant:
	var state := MISSION_1_SCENE.get_state()
	for node_index in state.get_node_count():
		if state.get_node_name(node_index) != node_name:
			continue
		for property_index in state.get_node_property_count(node_index):
			if state.get_node_property_name(node_index, property_index) == property:
				return state.get_node_property_value(node_index, property_index)
	return null


func test_mission_scene_has_the_shake_camera_at_the_screen_centre() -> void:
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	assert_eq(_mission_scene_value("Camera", "script"), ScreenShake)
	assert_eq(_mission_scene_value("Camera", "position"), screen / 2.0)


# the backgrounds overhang the screen in the scene so a shake never shows their edge
func test_mission_backgrounds_cover_the_shake() -> void:
	var screen := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	for background in ["BackgroundColour", "Background"]:
		assert_lt(_mission_scene_value(background, "offset_left"), -ScreenShake.MAX_OFFSET, background)
		assert_lt(_mission_scene_value(background, "offset_top"), -ScreenShake.MAX_OFFSET, background)
		assert_gt(_mission_scene_value(background, "offset_right"), screen.x + ScreenShake.MAX_OFFSET, background)
		assert_gt(_mission_scene_value(background, "offset_bottom"), screen.y + ScreenShake.MAX_OFFSET, background)


func test_camera_starts_still() -> void:
	assert_eq(camera.position, HOME)
	assert_eq(camera.offset, Vector2.ZERO)


func test_trauma_adds_up_and_caps_at_one() -> void:
	camera.add_trauma(0.6)
	camera.add_trauma(0.6)
	assert_eq(camera.trauma, 1.0)


func test_reduce_screen_shake_ignores_trauma() -> void:
	SettingsState.reduce_screen_shake = true
	camera.add_trauma(0.8)
	assert_eq(camera.trauma, 0.0)


func test_shake_fades_and_the_camera_settles() -> void:
	camera.add_trauma(0.5)
	camera._process(0.1)
	assert_gt(camera.trauma, 0.0)
	camera._process(5.0)
	camera._process(0.016)
	assert_eq(camera.trauma, 0.0)
	assert_eq(camera.offset, Vector2.ZERO)


# the finale zoom on a tank near the corner still keeps the whole view on screen
func test_focus_near_a_corner_stays_inside_the_screen() -> void:
	var tween: Tween = camera.focus_on(Vector2.ZERO, 2.0, 0.1)
	await tween.finished
	var screen := camera.get_viewport_rect().size
	assert_almost_eq(camera.zoom, Vector2(2.0, 2.0), Vector2.ONE * 0.01)
	assert_almost_eq(camera.position, screen / 4.0, Vector2.ONE * 0.5)


func test_reset_focus_returns_to_the_full_view() -> void:
	await camera.focus_on(Vector2(100, 100), 1.8, 0.05).finished
	await camera.reset_focus(0.05).finished
	assert_almost_eq(camera.zoom, Vector2.ONE, Vector2.ONE * 0.01)
	assert_almost_eq(camera.position, HOME, Vector2.ONE * 0.5)
