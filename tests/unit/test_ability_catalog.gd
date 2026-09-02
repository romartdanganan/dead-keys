extends GutTest

const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")


# Spread Shot is the one ability actually built this sprint, should be
# flagged implemented and selectable
func test_spread_shot_is_implemented() -> void:
	var ability := AbilityCatalog.get_ability("spread_shot")
	assert_false(ability.is_empty())
	assert_true(ability.implemented)


# the remaining 6 slots exist as placeholders but must stay locked
# (not selectable) until they're actually built in a future sprint
func test_locked_abilities_are_not_implemented() -> void:
	var locked_ids := [
		"ability_3", "ability_4",
		"ability_5", "ability_6", "ability_7", "ability_8"
	]
	for ability_id in locked_ids:
		var ability := AbilityCatalog.get_ability(ability_id)
		assert_false(ability.is_empty(), ability_id + " should exist")
		assert_false(ability.implemented, ability_id + " should not be implemented yet")


# an id that doesn't exist should return an empty dict, not null or an error
func test_get_ability_returns_empty_dict_for_unknown_id() -> void:
	var ability := AbilityCatalog.get_ability("not_a_real_ability")
	assert_true(ability.is_empty())


# sanity check matching GDD §2.2.3's 8-ability roster (1 built, 7 backlog)
func test_all_eight_ability_slots_exist() -> void:
	assert_eq(AbilityCatalog.ABILITIES.size(), 8)
