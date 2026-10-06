extends GutTest

# when each tutorial and new enemy callout fires, driven by the same signals the mission uses

const TutorialCalloutsScript := preload("res://scripts/missions/tutorial_callouts.gd")
const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const RUNNER_TYPE: EnemyTypeDef = preload("res://resources/enemies/runner.tres")
const TEST_SAVE_PATH := "user://test_tutorial.cfg"

var callouts: Node
var typing: TypingController
var manager: ZombieManager
var _original_path: String
var _original_seen: Dictionary


func before_each() -> void:
	_original_path = TutorialState.save_path
	_original_seen = TutorialState._seen.duplicate()
	TutorialState.save_path = TEST_SAVE_PATH
	TutorialState.reset()

	typing = TypingController.new()
	typing.word_list_path = ""
	add_child_autofree(typing)
	manager = ZombieManager.new()
	add_child_autofree(manager)
	callouts = TutorialCalloutsScript.new()
	add_child_autofree(callouts)
	callouts.setup(typing, manager, null)


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
	TutorialState.save_path = _original_path
	TutorialState._seen = _original_seen


func _spawned(type: EnemyTypeDef) -> Zombie:
	var zombie: Zombie = autofree(ZombieScene.instantiate())
	zombie.enemy_type = type
	return zombie


func test_first_wave_shows_the_typing_callout() -> void:
	manager.wave_started.emit(1, false)
	assert_true(TutorialState.has_seen("type_to_load"))
	assert_true(callouts.get_banner().is_showing())


func test_later_waves_do_not_show_the_typing_callout() -> void:
	manager.wave_started.emit(2, false)
	assert_false(TutorialState.has_seen("type_to_load"))


func test_a_seen_callout_is_not_shown_again() -> void:
	TutorialState.mark_seen("type_to_load")
	manager.wave_started.emit(1, false)
	assert_false(callouts.get_banner().is_showing())


func test_first_completed_word_shows_the_fire_callout() -> void:
	typing.word_completed.emit("code", 1)
	assert_true(TutorialState.has_seen("aim_and_fire"))


func test_charging_an_ability_shows_the_ability_callout() -> void:
	AbilityState.charged_changed.emit(true)
	assert_true(TutorialState.has_seen("ability_charged"))


func test_new_enemy_type_gets_a_callout() -> void:
	manager.zombie_spawned.emit(_spawned(RUNNER_TYPE))
	assert_true(TutorialState.has_seen("enemy_runner"))


# walkers are the baseline enemy and are covered by the typing callout
func test_walker_gets_no_enemy_callout() -> void:
	manager.zombie_spawned.emit(_spawned(WALKER_TYPE))
	assert_false(TutorialState.has_seen("enemy_walker"))


func test_every_planned_enemy_has_callout_text() -> void:
	for enemy_id in ["runner", "medic", "brute", "commander"]:
		assert_ne(TutorialCalloutsScript.enemy_callout_text(enemy_id), "", enemy_id)
	assert_eq(TutorialCalloutsScript.enemy_callout_text("walker"), "")
