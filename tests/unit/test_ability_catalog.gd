extends GutTest

const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")


# sanity check matching GDD §2.2.3's 8-ability roster
func test_all_eight_ability_slots_exist() -> void:
	assert_eq(AbilityCatalog.ABILITIES.size(), 8)


# every entry needs all required fields with the right types and a unique
# id, this never needs editing as abilities move from locked to
# implemented, whatever their id ends up being named
func test_every_ability_entry_has_required_fields_and_a_unique_id() -> void:
	var seen_ids: Array[String] = []
	for ability: Dictionary in AbilityCatalog.ABILITIES:
		assert_true(ability.has("id"), "missing id field")
		assert_true(ability.has("display_name"), "missing display_name field")
		assert_true(ability.has("description"), "missing description field")
		assert_true(ability.has("implemented"), "missing implemented field")
		assert_true(ability.has("cost"), "missing cost field")
		assert_typeof(ability.implemented, TYPE_BOOL, ability.id + "'s implemented should be a bool")
		assert_typeof(ability.cost, TYPE_INT, ability.id + "'s cost should be an int")
		assert_false(ability.id in seen_ids, "duplicate ability id: " + ability.id)
		seen_ids.append(ability.id)


# an ability flagged implemented should have a real description, not the
# unbuilt placeholder text, catches forgetting to update it when an
# ability actually gets built
func test_every_implemented_ability_has_a_real_description() -> void:
	for ability: Dictionary in AbilityCatalog.ABILITIES:
		if ability.implemented:
			assert_ne(
				ability.description,
				"Coming in a future sprint.",
				ability.id + " is implemented but still has the placeholder description"
			)


# get_ability() should round-trip correctly for every id actually present
# in the catalog, whatever the current roster of ids happens to be
func test_get_ability_returns_the_matching_entry_for_every_known_id() -> void:
	for ability: Dictionary in AbilityCatalog.ABILITIES:
		assert_eq(AbilityCatalog.get_ability(ability.id), ability)


# an id that doesn't exist should return an empty dict, not null or an error
func test_get_ability_returns_empty_dict_for_unknown_id() -> void:
	var ability := AbilityCatalog.get_ability("not_a_real_ability")
	assert_true(ability.is_empty())
