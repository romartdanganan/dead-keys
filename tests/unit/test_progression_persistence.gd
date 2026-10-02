extends GutTest

# checks gold and mission unlocks survive a save and reload, like closing the game

const ProgressionBackup := preload("res://tests/helpers/progression_backup.gd")

var _backup := ProgressionBackup.new()


func before_each() -> void:
	_backup.backup()


func after_each() -> void:
	_backup.restore()


func test_unlocked_mission_survives_save_and_reload() -> void:
	ProgressionManager.highest_unlocked = 2
	ProgressionManager.save_progression()

	# simulates a fresh launch where memory starts back at the default
	ProgressionManager.highest_unlocked = 1
	ProgressionManager.load_progression()

	assert_eq(ProgressionManager.highest_unlocked, 2)


func test_gold_survives_save_and_reload() -> void:
	ProgressionManager.gold = 125
	ProgressionManager.save_progression()

	ProgressionManager.gold = 0
	ProgressionManager.load_progression()

	assert_eq(ProgressionManager.gold, 125)


func test_owned_abilities_and_upgrades_survive_save_and_reload() -> void:
	ProgressionManager.owned_abilities = {"spread_shot": true, "ricochet": true}
	ProgressionManager.upgrade_levels = {"fire_rate": 2}
	ProgressionManager.save_progression()

	ProgressionManager.owned_abilities = {"spread_shot": true}
	ProgressionManager.upgrade_levels = {}
	ProgressionManager.load_progression()

	assert_true(ProgressionManager.is_ability_owned("ricochet"))
	assert_eq(ProgressionManager.get_upgrade_level("fire_rate"), 2)
