extends "res://scripts/missions/mission_1.gd"

# secure the shopping centre: mixed waves building up to the tank boss (GDD 5.2)
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")
const BRUTE_TYPE: EnemyTypeDef = preload("res://resources/enemies/brute.tres")
const COMMANDER_TYPE: EnemyTypeDef = preload("res://resources/enemies/commander.tres")
const TANK_TYPE: EnemyTypeDef = preload("res://resources/enemies/tank.tres")


func _init() -> void:
	mission_number = 3


func _build_mission_config() -> MissionConfigDef:
	# wave 1: walkers with runners rushing in behind
	var wave_1a := _make_wave(WALKER_TYPE, 4, 2.5, 1.0, 1)
	wave_1a.wait_for_clear = false
	var wave_1b := _make_wave(RUNNER_TYPE, 3, 2.0, 2.0, 1)

	# wave 2: a brute soaks shots while a medic keeps the walkers alive
	var wave_2a := _make_wave(BRUTE_TYPE, 1, 0.0, 2.5, 2)
	wave_2a.wait_for_clear = false
	var wave_2b := _make_wave(WALKER_TYPE, 4, 2.5, 1.5, 2)
	wave_2b.wait_for_clear = false
	var wave_2c := _make_wave(MEDIC_TYPE, 1, 0.0, 2.0, 2)

	# wave 3: a commander speeds up the walkers around it
	var wave_3a := _make_wave(COMMANDER_TYPE, 1, 0.0, 2.5, 3)
	wave_3a.wait_for_clear = false
	var wave_3b := _make_wave(WALKER_TYPE, 5, 2.0, 1.0, 3)

	# wave 4 (final): the tank with a slow trickle of escorts, tank kept to the
	# sides so it has the long way across the screen instead of the short top/bottom gap
	var wave_4a := _make_wave(TANK_TYPE, 1, 0.0, 3.0, 4)
	wave_4a.wait_for_clear = false
	wave_4a.side_spawn_only = true
	var wave_4b := _make_wave(WALKER_TYPE, 4, 4.0, 4.0, 4)
	wave_4b.wait_for_clear = false
	var wave_4c := _make_wave(RUNNER_TYPE, 3, 3.0, 4.0, 4)

	var mission := MissionConfigDef.new()
	mission.mission_id = "mission_3"
	mission.mission_name = "Secure the Shopping Centre"
	mission.waves = [wave_1a, wave_1b, wave_2a, wave_2b, wave_2c, wave_3a, wave_3b, wave_4a, wave_4b, wave_4c]
	mission.base_coin_reward = 100
	return mission


func _make_wave(type: EnemyTypeDef, count: int, interval: float, delay: float, display_number: int) -> WaveEntry:
	var wave := WaveEntry.new()
	wave.enemy_type = type
	wave.count = count
	wave.spawn_interval = interval
	wave.start_delay = delay
	wave.display_wave_number = display_number
	return wave
