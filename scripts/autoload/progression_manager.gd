extends Node
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")
const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")
const MissionRating := preload("res://scripts/missions/mission_rating.gd")
signal gold_changed(new_gold: int)
signal upgrade_purchased(track_id: String, new_level: int)
signal ability_unlocked(ability_id: String)
var gold: int = 0
var highest_unlocked: int = 1 #structure only for now, for future uses for level unlocked
var upgrade_levels: Dictionary = {} # track_id (String) -> level (int), defaults to 0
const SAVE_PATH = "user://progression.cfg"
# ability ownership: player starts with Spread Shot only, the rest are
# bought on the Ability Select screen. ability_id (String) -> owned (bool)
var owned_abilities: Dictionary = {"spread_shot": true}
# best medal won on each mission, mission number (int) -> medal name
var best_medals: Dictionary = {}

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

# attempts to purchase the next level of a track; returns false (no gold
# spent) if already maxed or gold is insufficient
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
	config.set_value("progression", "owned_abilities", owned_abilities)
	config.set_value("progression", "best_medals", best_medals)
	config.save(SAVE_PATH)


func load_progression() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return #first lanuch, no save file yet. Keep defaults
	
	gold = config.get_value("progression","gold", 0)
	upgrade_levels = config.get_value("progression", "upgrade_levels",{})
	highest_unlocked = config.get_value("progression", "highest_unlocked", 1)
	owned_abilities = config.get_value("progression", "owned_abilities", owned_abilities)
	best_medals = config.get_value("progression", "best_medals", {})
	gold_changed.emit(gold)
	
#DEV/DEBUG ONLY. wiped all of progression with no comfirmation.
#remove later on.
func reset_progression() -> void:
	gold = 0
	upgrade_levels = {}
	highest_unlocked = 1
	owned_abilities = {"spread_shot": true}
	best_medals = {}
	save_progression()
	gold_changed.emit(gold)

#Medal functions:
# NONE until the mission has been won at least once
func get_best_medal(mission_id: int) -> String:
	return best_medals.get(mission_id, MissionRating.NONE)


# only replaces the saved medal when the new one is better, returns true if it did
func set_best_medal(mission_id: int, medal: String) -> bool:
	if not MissionRating.is_better(medal, get_best_medal(mission_id)):
		return false
	best_medals[mission_id] = medal
	return true

#Abilites functiions:
func is_ability_owned(ability_id: String) -> bool:
	return owned_abilities.get(ability_id, false)


# attempts to buy an ability at its flat AbilityCatalog cost; returns false
# (no gold spent) if already owned, unknown, not yet implemented, or gold
# is insufficient
func purchase_ability(ability_id: String) -> bool:
	if is_ability_owned(ability_id):
		return false

	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty() or not ability.implemented:
		return false

	var cost: int = ability.get("cost", 0)
	if not spend_gold(cost):
		return false

	owned_abilities[ability_id] = true
	ability_unlocked.emit(ability_id)
	save_progression()
	Audio.play("purchase")
	return true
	
func is_mission_unlocked(mission_id: int) -> bool:
	return mission_id >= 1 and mission_id <= highest_unlocked
	

func unlock_next_mission(completed_id: int) -> void:
	#only move forward only (replaying mission 1 never relocked mission 2)
	highest_unlocked = maxi(highest_unlocked, completed_id + 1)
	if highest_unlocked > 6:
		highest_unlocked = 6
