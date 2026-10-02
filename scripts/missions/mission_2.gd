extends "res://scripts/missions/mission_1.gd"

# hold the hospital: same gameplay as mission 1, only the waves change
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")


func _init() -> void:
	mission_number = 2


func _build_mission_config() -> MissionConfigDef:
	# wave 1: walkers with a medic spawning in behind them to heal
	var wave_1a := _make_wave(WALKER_TYPE, 4, 3.0, 1.0, 1)
	wave_1a.wait_for_clear = false
	var wave_1b := _make_wave(MEDIC_TYPE, 1, 0.0, 2.0, 1)

	# wave 2: runners rush in, then walkers backed by a medic
	var wave_2a := _make_wave(RUNNER_TYPE, 3, 2.0, 2.5, 2)
	var wave_2b := _make_wave(WALKER_TYPE, 3, 2.5, 1.5, 2)
	wave_2b.wait_for_clear = false
	var wave_2c := _make_wave(MEDIC_TYPE, 1, 0.0, 2.0, 2)

	# wave 3 (final): walkers and runners together with two medics
	var wave_3a := _make_wave(WALKER_TYPE, 4, 2.5, 2.5, 3)
	wave_3a.wait_for_clear = false
	var wave_3b := _make_wave(RUNNER_TYPE, 3, 2.0, 1.0, 3)
	wave_3b.wait_for_clear = false
	var wave_3c := _make_wave(MEDIC_TYPE, 2, 3.0, 1.5, 3)

	var mission := MissionConfigDef.new()
	mission.mission_id = "mission_2"
	mission.mission_name = "Hold the Hospital"
	mission.waves = [wave_1a, wave_1b, wave_2a, wave_2b, wave_2c, wave_3a, wave_3b, wave_3c]
	mission.base_coin_reward = 75
	return mission


func _make_wave(type: EnemyTypeDef, count: int, interval: float, delay: float, display_number: int) -> WaveEntry:
	var wave := WaveEntry.new()
	wave.enemy_type = type
	wave.count = count
	wave.spawn_interval = interval
	wave.start_delay = delay
	wave.display_wave_number = display_number
	return wave
