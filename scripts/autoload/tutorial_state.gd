extends Node

# remembers which tutorial and new enemy callouts the player has already seen

const DEFAULT_SAVE_PATH := "user://tutorial.cfg"

# tests point this at a throwaway file so the real save is never touched
var save_path: String = DEFAULT_SAVE_PATH
var _seen: Dictionary = {}


func _ready() -> void:
	load_seen()


func has_seen(callout_id: String) -> bool:
	return _seen.get(callout_id, false)


func mark_seen(callout_id: String) -> void:
	if has_seen(callout_id):
		return
	_seen[callout_id] = true
	save_seen()


# lets a fresh playtester see every callout again
func reset() -> void:
	_seen = {}
	save_seen()


func save_seen() -> void:
	var config := ConfigFile.new()
	config.set_value("tutorial", "seen", _seen)
	config.save(save_path)


func load_seen() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		_seen = {}
		return
	_seen = config.get_value("tutorial", "seen", {})
