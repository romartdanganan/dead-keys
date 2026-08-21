extends GutTest

const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")


# a known track id should return its full data dictionary
func test_get_track_returns_known_track() -> void:
	var track := UpgradeCatalog.get_track("fire_rate")
	assert_false(track.is_empty())
	assert_eq(track.display_name, "Fire Rate")


# an id that doesn't exist should return an empty dict, not null or an error
func test_get_track_returns_empty_dict_for_unknown_id() -> void:
	var track := UpgradeCatalog.get_track("not_a_real_track")
	assert_true(track.is_empty())


# level 0 means nothing purchased yet, should resolve to base_value
func test_get_level_value_at_level_zero_returns_base_value() -> void:
	var value = UpgradeCatalog.get_level_value("fire_rate", 0)
	assert_eq(value, 2.0)


# each purchased level should return that level's specific effect value
func test_get_level_value_returns_correct_value_per_level() -> void:
	assert_eq(UpgradeCatalog.get_level_value("fire_rate", 1), 2.5)
	assert_eq(UpgradeCatalog.get_level_value("fire_rate", 2), 3.0)
	assert_eq(UpgradeCatalog.get_level_value("fire_rate", 3), 4.0)


# a level beyond the track's max should clamp to the max level's value,
# not error or extrapolate past it
func test_get_level_value_clamps_above_max_level() -> void:
	var value = UpgradeCatalog.get_level_value("fire_rate", 99)
	assert_eq(value, 4.0)


# max_level should match the number of purchasable levels per GDD §2.6.1
func test_get_max_level_matches_documented_levels() -> void:
	assert_eq(UpgradeCatalog.get_max_level("fire_rate"), 3)
	assert_eq(UpgradeCatalog.get_max_level("extra_life"), 2)


# next-level costs should match GDD §2.6.1's documented per-level pricing
func test_get_cost_for_next_level_follows_gdd_section_2_6_1() -> void:
	assert_eq(UpgradeCatalog.get_cost_for_next_level("fire_rate", 0), 150)
	assert_eq(UpgradeCatalog.get_cost_for_next_level("fire_rate", 1), 250)
	assert_eq(UpgradeCatalog.get_cost_for_next_level("fire_rate", 2), 400)


# once already at max level, there is no next cost, should return -1
func test_get_cost_for_next_level_returns_negative_one_when_maxed() -> void:
	var cost := UpgradeCatalog.get_cost_for_next_level("fire_rate", 3)
	assert_eq(cost, -1)


# sanity check that none of the 7 tracks were accidentally dropped
func test_all_seven_tracks_exist() -> void:
	var expected_ids := [
		"fire_rate", "bullet_damage", "magazine_capacity",
		"fortified_wall", "extra_life", "jam_duration", "mistake_leniency"
	]
	for track_id in expected_ids:
		assert_false(UpgradeCatalog.get_track(track_id).is_empty(), track_id + " should exist")
