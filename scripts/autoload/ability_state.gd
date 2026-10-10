extends Node

# preload rather than rely on the class_name global (needs an editor rescan
# to register on a fresh checkout / new machine)
const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")

# equipped ability + mission-charge state (#24).
#
# the combo in MistakeSystem charges this after 5 typed words in a row, the charge
# is stored until the player presses use_ability (WeaponController.try_fire_ability)

signal charged_changed(is_charged: bool)

var equipped_ability_id: String = "homing_shot"
var is_charged: bool = false


func equip(ability_id: String) -> void:
	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty() or not ability.implemented:
		return
	if not ProgressionManager.is_ability_owned(ability_id):
		return
	equipped_ability_id = ability_id


func set_charged(value: bool) -> void:
	is_charged = value
	charged_changed.emit(is_charged)


func consume_charge() -> void:
	if is_charged:
		set_charged(false)


# called at mission start so a leftover charge from a previous run never
# carries over
func reset_for_mission() -> void:
	set_charged(false)
