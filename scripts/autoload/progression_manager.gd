extends Node
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")
signal gold_changed(new_gold: int)
signal upgrade_purchased(track_id: String, new_level: int)


func _ready() -> void:
	load_progression()
	
	
#GOLD Methods
var gold: int = 0
var highest_unlocked: int = 1

var upgrade_levels: Dictionary = {}

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


func get_upgrade_level(track_id: String) -> int:
	return upgrade_levels.get(track_id, 0)


#Upgrade-level methods
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
	save_progression()
	return true


func get_upgrade_value(track_id: String) -> Variant:
	return UpgradeCatalog.get_level_value(track_id, get_upgrade_level(track_id))

#save and load functions 

const SAVE_PATH = "user://progression.cfg"

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
		return #no save file yet, cause of first lanch
	
	gold = config.get_value("progression","gold", 0)
	upgrade_levels = config.get_value("progression", "upgrade_levels",{})
	highest_unlocked = config.get_value("progression", "highest_unlocked", 1)
	gold_changed.emit(gold)
