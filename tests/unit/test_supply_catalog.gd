extends GutTest

const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")


# sanity check that all 4 crate types from GDD §2.2.4 are present
func test_all_four_crate_types_exist() -> void:
	var expected_ids := ["ammo_crate", "medical_crate", "combat_crate", "emergency_crate"]
	for supply_id in expected_ids:
		assert_false(SupplyCatalog.get_supply(supply_id).is_empty(), supply_id + " should exist")


# every crate's cost should sit inside GDD §2.6's documented 40-120 coin
# range for Mission Supplies, catches an accidental balance typo
func test_costs_fall_within_gdd_section_2_6_documented_range() -> void:
	for supply: Dictionary in SupplyCatalog.SUPPLIES:
		assert_between(supply.cost, 40, 120, supply.id + " cost should be within GDD's 40-120 range")


# an id that doesn't exist should return an empty dict, not null or an error
func test_get_supply_returns_empty_dict_for_unknown_id() -> void:
	var supply := SupplyCatalog.get_supply("not_a_real_crate")
	assert_true(supply.is_empty())
