extends GutTest

const MissionCatalog := preload("res://scripts/resources/mission_catalog.gd")


# every listed mission should point at a scene that actually exists
func test_every_listed_mission_scene_exists() -> void:
	for mission_id: int in MissionCatalog.MISSION_SCENES:
		var path := MissionCatalog.get_scene_path(mission_id)
		assert_true(ResourceLoader.exists(path), "missing scene for mission %d: %s" % [mission_id, path])


func test_missions_one_to_three_are_built() -> void:
	assert_true(MissionCatalog.has_mission(1))
	assert_true(MissionCatalog.has_mission(2))
	assert_true(MissionCatalog.has_mission(3))


# next mission button relies on unbuilt missions returning empty
func test_unbuilt_mission_returns_empty_path() -> void:
	assert_false(MissionCatalog.has_mission(4))
	assert_eq(MissionCatalog.get_scene_path(4), "")


# default must stay true so existing missions keep their old pacing
func test_wave_entry_waits_for_clear_by_default() -> void:
	var wave := WaveEntry.new()
	assert_true(wave.wait_for_clear)
