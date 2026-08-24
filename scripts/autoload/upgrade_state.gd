extends Node

# preload rather than rely on the class_name global (which needs an editor
# filesystem rescan to register on a fresh checkout / new machine)
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")

# TEMPORARY local store for gold + purchased upgrade levels (#25).
#
# This is intentionally NOT persistent and is not the real economy system.
# Issue #26 ("Implement gold and save/progression system") owns the real
# ProgressionManager autoload: mission-reward gold, save/load, and mission
# unlock state.
#
# Integration note for #26: replace this autoload with ProgressionManager,
# keeping these method names identical so the shop UI (upgrade_shop.gd,
# upgrade_row.gd) and gameplay effect application (gameplay_prototype.gd,
# weapon_controller.gd, mistake_system.gd) don't need to change at all:
#   get_gold(), can_afford(), spend_gold(), get_upgrade_level(),
#   purchase_upgrade(), get_upgrade_value()
# Track ids/costs/values already live in one place: UpgradeCatalog
# (scripts/resources/upgrade_catalog.gd). #26 should persist upgrade levels
# keyed by the same track "id" strings used there.

signal gold_changed(new_gold: int)
signal upgrade_purchased(track_id: String, new_level: int)

# placeholder starting gold for local testing until #26 wires in real
# mission-reward gold and save/load.
var gold: int = 500

var upgrade_levels: Dictionary = {} # track_id (String) -> level (int), defaults to 0


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
	return true


# convenience: current effective value of a track given its purchased level
func get_upgrade_value(track_id: String) -> Variant:
	return UpgradeCatalog.get_level_value(track_id, get_upgrade_level(track_id))
