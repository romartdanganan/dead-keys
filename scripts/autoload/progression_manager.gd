extends Node
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")
signal gold_changed(new_gold: int)
signal upgrade_purchased(track_id: String, new_level: int)
var gold: int = 0
var highest_unlocked: int = 1 #structure only for now, for future uses for level unlocked
var upgrade_levels: Dictionary = {}
const SAVE_PATH = "user://progression.cfg"


func _ready() -> void:
	load_progression()

#GOLD Functions: 
func get_gold() -> int:
	return gold

func can_afford(amount: int) -> bool:
	return gold >= amount

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

#Upgrade-level Functions:
func get_upgrade_level(track_id: String) -> int:
	return upgrade_levels.get(track_id, 0)

func purchase_upgrade(track_id: String) -> bool:
	var current_level := get_upgrade_level(track_id)
	var max_level := UpgradeCatalog.get_max_level(track_id)

	if current_level >= max_level:
		return false

	var cost := UpgradeCatalog.get_cost_for_next_level(track_id, current_level)
	if cost < 0:
		return false

	if not spend_gold(cost):
		return false

	var new_level := current_level + 1
	upgrade_levels[track_id] = new_level
	upgrade_purchased.emit(track_id, new_level)
	# save here because purchases happen at the Upgrade Shop
	# between missions, not just on mission completion. Without this,
	# buying an upgrade then quitting loses it.
	save_progression()
	return true

#Return type is a Variant to track all values types of upgrades in the store
func get_upgrade_value(track_id: String) -> Variant:
	return UpgradeCatalog.get_level_value(track_id, get_upgrade_level(track_id))

#Progression Functions:

#key name MUST match the get_value() in load_progression()
# a mismatch DOES NOT CAUSE ERROR and silently fall back to default

func save_progression() -> void: 
	var config := ConfigFile.new()
	config.set_value("progression", "gold", gold)
	config.set_value("progression", "upgrade_levels", upgrade_levels)
	config.set_value("progression", "highest_unlocked", highest_unlocked)
	config.save(SAVE_PATH)


func load_progression() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return #first lanuch, no save file yet. Keep defaults
	
	gold = config.get_value("progression","gold", 0)
	upgrade_levels = config.get_value("progression", "upgrade_levels",{})
	highest_unlocked = config.get_value("progression", "highest_unlocked", 1)
	gold_changed.emit(gold)
	
#DEV/DEBUG ONLY. wipe all of progression with no comfirmation.
#remove later on.
func reset_progression() -> void:
	gold = 0
	upgrade_levels = {}
	highest_unlocked = 1
	save_progression()
	gold_changed.emit(gold)
