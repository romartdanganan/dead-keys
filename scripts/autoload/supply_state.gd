extends Node

# preload rather than rely on the class_name global (needs an editor rescan
# to register on a fresh checkout / new machine)
const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")

# pre-mission Supply loadout (#29): 3 numbered slots, purchased against the
# same gold pool as the Upgrade Shop (UpgradeState.gold), not a second one.
# Per GDD §2.6, supplies are repurchased every mission, so this clears when
# a mission is left, see gameplay_prototype.gd's return_to_home_base().

signal loadout_changed

const SLOT_COUNT := 3

var equipped_slots: Array[String] = ["", "", ""]


func get_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return ""
	return equipped_slots[slot_index]


func purchase_into_slot(slot_index: int, supply_id: String) -> bool:
	if slot_index < 0 or slot_index >= SLOT_COUNT:
		return false

	var supply := SupplyCatalog.get_supply(supply_id)
	if supply.is_empty():
		return false

	if not UpgradeState.spend_gold(supply.cost):
		return false

	equipped_slots[slot_index] = supply_id
	loadout_changed.emit()
	return true


func first_empty_slot() -> int:
	for i in SLOT_COUNT:
		if equipped_slots[i] == "":
			return i
	return -1


func clear_loadout() -> void:
	equipped_slots = ["", "", ""]
	loadout_changed.emit()
