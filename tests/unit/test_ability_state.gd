extends GutTest

# equipping rules and the combo charge lifecycle on the AbilityState autoload

var _original_equipped: String
var _original_charged: bool
var _original_owned: Dictionary


func before_each() -> void:
	_original_equipped = AbilityState.equipped_ability_id
	_original_charged = AbilityState.is_charged
	_original_owned = ProgressionManager.owned_abilities.duplicate()
	ProgressionManager.owned_abilities = {"spread_shot": true}
	AbilityState.equipped_ability_id = "spread_shot"
	AbilityState.is_charged = false


func after_each() -> void:
	AbilityState.equipped_ability_id = _original_equipped
	AbilityState.is_charged = _original_charged
	ProgressionManager.owned_abilities = _original_owned


func test_equip_owned_ability_works() -> void:
	ProgressionManager.owned_abilities["ricochet"] = true
	AbilityState.equip("ricochet")
	assert_eq(AbilityState.equipped_ability_id, "ricochet")


func test_equip_unowned_ability_is_ignored() -> void:
	AbilityState.equip("ricochet")
	assert_eq(AbilityState.equipped_ability_id, "spread_shot")


func test_equip_unknown_ability_is_ignored() -> void:
	AbilityState.equip("not_a_real_ability")
	assert_eq(AbilityState.equipped_ability_id, "spread_shot")


func test_set_charged_updates_state_and_emits_signal() -> void:
	watch_signals(AbilityState)
	AbilityState.set_charged(true)

	assert_true(AbilityState.is_charged)
	assert_signal_emitted_with_parameters(AbilityState, "charged_changed", [true])


func test_consume_charge_clears_a_charge() -> void:
	AbilityState.set_charged(true)
	AbilityState.consume_charge()
	assert_false(AbilityState.is_charged)


func test_consume_charge_without_a_charge_emits_nothing() -> void:
	watch_signals(AbilityState)
	AbilityState.consume_charge()
	assert_signal_not_emitted(AbilityState, "charged_changed")


# a charge from a previous mission must never carry over
func test_reset_for_mission_discards_a_leftover_charge() -> void:
	AbilityState.set_charged(true)
	AbilityState.reset_for_mission()
	assert_false(AbilityState.is_charged)
