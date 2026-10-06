extends GutTest

# seen/not seen tracking for tutorial callouts, uses a throwaway save file

const TEST_SAVE_PATH := "user://test_tutorial.cfg"

var _original_path: String
var _original_seen: Dictionary


func before_each() -> void:
	_original_path = TutorialState.save_path
	_original_seen = TutorialState._seen.duplicate()
	TutorialState.save_path = TEST_SAVE_PATH
	TutorialState.reset()


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	TutorialState.save_path = _original_path
	TutorialState._seen = _original_seen


func test_callouts_start_unseen() -> void:
	assert_false(TutorialState.has_seen("type_to_load"))


func test_mark_seen_remembers_a_callout() -> void:
	TutorialState.mark_seen("type_to_load")
	assert_true(TutorialState.has_seen("type_to_load"))
	assert_false(TutorialState.has_seen("aim_and_fire"))


func test_seen_callouts_survive_a_reload() -> void:
	TutorialState.mark_seen("enemy_medic")

	# simulates restarting the game
	TutorialState._seen = {}
	TutorialState.load_seen()

	assert_true(TutorialState.has_seen("enemy_medic"))


func test_reset_brings_every_callout_back() -> void:
	TutorialState.mark_seen("type_to_load")
	TutorialState.reset()
	TutorialState.load_seen()
	assert_false(TutorialState.has_seen("type_to_load"))
