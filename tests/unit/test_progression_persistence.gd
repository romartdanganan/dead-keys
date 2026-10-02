extends GutTest

# checks gold and mission unlocks survive a save and reload, like closing the game
# backs up the real save file first so running tests never wipes progress

var _had_save: bool = false
var _save_backup: PackedByteArray
var _state_backup: Dictionary


func before_each() -> void:
	_had_save = FileAccess.file_exists(ProgressionManager.SAVE_PATH)
	if _had_save:
		_save_backup = FileAccess.get_file_as_bytes(ProgressionManager.SAVE_PATH)
	_state_backup = {
		"gold": ProgressionManager.gold,
		"highest_unlocked": ProgressionManager.highest_unlocked,
		"upgrade_levels": ProgressionManager.upgrade_levels.duplicate(),
		"owned_abilities": ProgressionManager.owned_abilities.duplicate(),
	}


func after_each() -> void:
	# put the player's real save and in-memory state back
	if _had_save:
		var file := FileAccess.open(ProgressionManager.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(_save_backup)
		file.close()
	elif FileAccess.file_exists(ProgressionManager.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ProgressionManager.SAVE_PATH))
	ProgressionManager.gold = _state_backup.gold
	ProgressionManager.highest_unlocked = _state_backup.highest_unlocked
	ProgressionManager.upgrade_levels = _state_backup.upgrade_levels
	ProgressionManager.owned_abilities = _state_backup.owned_abilities


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
