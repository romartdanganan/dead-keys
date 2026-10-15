extends RefCounted

# builds endless survival rounds, each one a little bigger than the last
# new enemy types join over time and every fifth round brings a tank boss

const WALKER: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const RUNNER: EnemyTypeDef = preload("res://resources/enemies/runner.tres")
const MEDIC: EnemyTypeDef = preload("res://resources/enemies/medic.tres")
const BRUTE: EnemyTypeDef = preload("res://resources/enemies/brute.tres")
const COMMANDER: EnemyTypeDef = preload("res://resources/enemies/commander.tres")
const TANK: EnemyTypeDef = preload("res://resources/enemies/tank.tres")

const BOSS_EVERY: int = 5
const MAX_WALKERS: int = 16
const MAX_RUNNERS: int = 6
const SLOWEST_INTERVAL: float = 2.8
const FASTEST_INTERVAL: float = 1.0


# round 1 is just three walkers with short words, then one new idea at a time
static func build_round(round_number: int) -> MissionConfigDef:
	var waves: Array[WaveEntry] = []
	var interval := maxf(SLOWEST_INTERVAL - 0.1 * round_number, FASTEST_INTERVAL)

	# word length grows slowly too, all lengths only from round 8
	var walker_buckets: Array[int] = []
	if round_number <= 2:
		walker_buckets = [1]
	elif round_number <= 4:
		walker_buckets = [1, 2]
	elif round_number <= 7:
		walker_buckets = [1, 2, 3]
	waves.append(_wave(WALKER, mini(2 + round_number, MAX_WALKERS), interval, 1.0, walker_buckets))

	if round_number >= 3:
		waves.append(_wave(RUNNER, mini(1 + int((round_number - 3) / 2.0), MAX_RUNNERS), interval, 2.0, [1]))
	if round_number >= 5:
		waves.append(_wave(MEDIC, mini(1 + int((round_number - 5) / 5.0), 2), 0.0, 2.0))
	if round_number >= 6:
		waves.append(_wave(BRUTE, mini(1 + int((round_number - 6) / 4.0), 3), interval * 2.0, 2.0))
	if round_number >= 8:
		waves.append(_wave(COMMANDER, mini(1 + int((round_number - 8) / 5.0), 2), 0.0, 2.0))
	if is_boss_round(round_number):
		var tank := _wave(TANK, 1, 0.0, 2.0, [3, 4])
		tank.side_spawn_only = true
		waves.append(tank)

	var config := MissionConfigDef.new()
	config.mission_id = "endless"
	config.mission_name = "Endless Survival"
	config.waves = waves
	config.base_coin_reward = 0
	return config


static func is_boss_round(round_number: int) -> bool:
	return round_number % BOSS_EVERY == 0


static func _wave(type: EnemyTypeDef, count: int, interval: float, delay: float, buckets: Array[int] = []) -> WaveEntry:
	var wave := WaveEntry.new()
	wave.enemy_type = type
	wave.count = count
	wave.spawn_interval = interval
	wave.start_delay = delay
	# every batch streams in behind the last, the round ends once all of them are dead
	wave.wait_for_clear = false
	# one announcement per round, the endless mission shows its own round number
	wave.display_wave_number = 1
	wave.allowed_buckets = buckets
	return wave
