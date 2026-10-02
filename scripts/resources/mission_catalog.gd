extends RefCounted

# mission id to scene path, only missions that actually have a scene go here
const MISSION_SCENES: Dictionary = {
	1: "res://scenes/missions/mission_1.tscn",
	2: "res://scenes/missions/mission_2.tscn",
}


# empty string when that mission hasn't been built yet
static func get_scene_path(mission_id: int) -> String:
	return MISSION_SCENES.get(mission_id, "")


static func has_mission(mission_id: int) -> bool:
	return MISSION_SCENES.has(mission_id)
