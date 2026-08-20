class_name UpgradeCatalog
extends RefCounted

# Single source of truth for the Permanent Upgrade Tracks (GDD §2.6.1, #25).
#
# "id" is the stable key used for persistence — issue #26 (ProgressionManager)
# should store purchased levels keyed by this same id string.
#
# "levels" holds one entry per purchasable level, in order (index 0 = level 1).
# Level 0 (nothing purchased yet) is not in this array — it always resolves to
# "base_value" below, which also matches the documented GDD baseline for each
# stat (e.g. fire_rate base_value 2.0 shots/s, per §2.5).

const TRACKS: Array[Dictionary] = [
	{
		"id": "fire_rate",
		"category": "Weapon",
		"display_name": "Fire Rate",
		"unit_suffix": " shots/s",
		"base_value": 2.0,
		"levels": [
			{"cost": 150, "value": 2.5},
			{"cost": 250, "value": 3.0},
			{"cost": 400, "value": 4.0},
		],
	},
	{
		"id": "bullet_damage",
		"category": "Weapon",
		"display_name": "Bullet Damage",
		"unit_suffix": " dmg/hit",
		"base_value": 10,
		"levels": [
			{"cost": 150, "value": 12},
			{"cost": 300, "value": 14},
			{"cost": 500, "value": 16},
		],
	},
	{
		"id": "magazine_capacity",
		"category": "Weapon",
		"display_name": "Magazine Capacity",
		"unit_suffix": " max ammo",
		"base_value": 8,
		"levels": [
			{"cost": 100, "value": 12},
			{"cost": 200, "value": 16},
			{"cost": 350, "value": 20},
		],
	},
	{
		"id": "fortified_wall",
		"category": "Base",
		"display_name": "Fortified Wall",
		"unit_suffix": " max wall HP",
		"base_value": 100,
		"levels": [
			{"cost": 100, "value": 125},
			{"cost": 200, "value": 150},
			{"cost": 350, "value": 175},
		],
	},
	{
		"id": "extra_life",
		"category": "Base",
		"display_name": "Extra Life",
		"unit_suffix": " lives",
		"base_value": 1,
		"levels": [
			{"cost": 300, "value": 2},
			{"cost": 500, "value": 3},
		],
	},
	{
		"id": "jam_duration",
		"category": "Base",
		"display_name": "Jam Duration",
		"unit_suffix": "s jam",
		"base_value": 2.0,
		"levels": [
			{"cost": 150, "value": 1.5},
			{"cost": 250, "value": 1.0},
		],
	},
	{
		"id": "mistake_leniency",
		"category": "Base",
		"display_name": "Mistake Leniency",
		"unit_suffix": " mistakes before ammo loss",
		"base_value": 1,
		"levels": [
			{"cost": 200, "value": 2},
			{"cost": 350, "value": 3},
		],
	},
]


static func get_track(track_id: String) -> Dictionary:
	for track: Dictionary in TRACKS:
		if track.id == track_id:
			return track
	return {}


# returns the effect value for a given track at a given purchased level
# (level 0 = base_value, i.e. nothing purchased yet)
static func get_level_value(track_id: String, level: int) -> Variant:
	var track := get_track(track_id)
	if track.is_empty():
		return null

	var levels: Array = track.levels
	var clamped_level: int = clampi(level, 0, levels.size())

	if clamped_level == 0:
		return track.base_value

	return levels[clamped_level - 1].value


static func get_max_level(track_id: String) -> int:
	var track := get_track(track_id)
	if track.is_empty():
		return 0
	return (track.levels as Array).size()


# gold cost to go from current_level to current_level + 1, or -1 if already maxed
static func get_cost_for_next_level(track_id: String, current_level: int) -> int:
	var track := get_track(track_id)
	if track.is_empty():
		return -1

	var levels: Array = track.levels
	if current_level >= levels.size():
		return -1

	return levels[current_level].cost
