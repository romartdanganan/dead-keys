extends RefCounted

# backs up and restores progression so tests never touch the player's real save

var _had_save: bool = false
var _save_bytes: PackedByteArray
var _state: Dictionary


func backup() -> void:
	_had_save = FileAccess.file_exists(ProgressionManager.SAVE_PATH)
	if _had_save:
		_save_bytes = FileAccess.get_file_as_bytes(ProgressionManager.SAVE_PATH)
	_state = {
		"gold": ProgressionManager.gold,
		"highest_unlocked": ProgressionManager.highest_unlocked,
		"upgrade_levels": ProgressionManager.upgrade_levels.duplicate(),
		"owned_abilities": ProgressionManager.owned_abilities.duplicate(),
	}


func restore() -> void:
	if _had_save:
		var file := FileAccess.open(ProgressionManager.SAVE_PATH, FileAccess.WRITE)
		file.store_buffer(_save_bytes)
		file.close()
	elif FileAccess.file_exists(ProgressionManager.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ProgressionManager.SAVE_PATH))
	ProgressionManager.gold = _state.gold
	ProgressionManager.highest_unlocked = _state.highest_unlocked
	ProgressionManager.upgrade_levels = _state.upgrade_levels
	ProgressionManager.owned_abilities = _state.owned_abilities
