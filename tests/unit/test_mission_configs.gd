extends GutTest

# wave setup for each mission, built straight from the mission scripts

const Mission1Script := preload("res://scripts/missions/mission_1.gd")
const Mission2Script := preload("res://scripts/missions/mission_2.gd")
const Mission3Script := preload("res://scripts/missions/mission_3.gd")
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")
const BRUTE_TYPE: EnemyTypeDef = preload("res://resources/enemies/brute.tres")
const TANK_TYPE: EnemyTypeDef = preload("res://resources/enemies/tank.tres")


func _config_for(script: GDScript) -> MissionConfigDef:
	var mission: Node = autofree(script.new())
	return mission._build_mission_config()


func test_mission_numbers_match_their_scripts() -> void:
	assert_eq(autofree(Mission1Script.new()).mission_number, 1)
	assert_eq(autofree(Mission2Script.new()).mission_number, 2)
	assert_eq(autofree(Mission3Script.new()).mission_number, 3)


func test_every_wave_has_an_enemy_type_and_a_count() -> void:
	for script: GDScript in [Mission1Script, Mission2Script, Mission3Script]:
		var config := _config_for(script)
		assert_gt(config.waves.size(), 0, config.mission_id + " has no waves")
		for wave in config.waves:
			assert_not_null(wave.enemy_type, config.mission_id + " has a wave with no enemy type")
			assert_gt(wave.count, 0, config.mission_id + " has an empty wave")


# GDD 2.6 base reward range per mission
func test_rewards_are_within_gdd_range() -> void:
	for script: GDScript in [Mission1Script, Mission2Script, Mission3Script]:
		var config := _config_for(script)
		assert_between(config.base_coin_reward, 50, 150, config.mission_id)


func test_mission_2_pays_more_than_mission_1() -> void:
	assert_gt(_config_for(Mission2Script).base_coin_reward, _config_for(Mission1Script).base_coin_reward)


func test_mission_3_pays_more_than_mission_2() -> void:
	assert_gt(_config_for(Mission3Script).base_coin_reward, _config_for(Mission2Script).base_coin_reward)


# mission 1 pacing was tuned with every batch waiting, it should stay that way
func test_mission_1_batches_all_wait_for_clear() -> void:
	for wave in _config_for(Mission1Script).waves:
		assert_true(wave.wait_for_clear)


func test_mission_2_introduces_medics() -> void:
	var has_medic := false
	for wave in _config_for(Mission2Script).waves:
		if wave.enemy_type == MEDIC_TYPE:
			has_medic = true
	assert_true(has_medic)


# a medic batch only matters if the batch before it is still alive to heal
func test_medics_spawn_alongside_other_zombies() -> void:
	for script: GDScript in [Mission2Script, Mission3Script]:
		var waves := _config_for(script).waves
		for i in waves.size():
			if waves[i].enemy_type == MEDIC_TYPE:
				assert_gt(i, 0, "a medic batch can't be first")
				assert_false(waves[i - 1].wait_for_clear, "medic batch %d spawns alone" % i)


# GDD 5.2 puts the brute's first appearance in mission 2
func test_mission_2_introduces_the_brute() -> void:
	var has_brute := false
	for wave in _config_for(Mission2Script).waves:
		if wave.enemy_type == BRUTE_TYPE:
			has_brute = true
	assert_true(has_brute)


func test_mission_2_shows_three_waves() -> void:
	var manager := ZombieManager.new()
	manager.mission_config = _config_for(Mission2Script)
	assert_eq(manager._compute_max_display_wave_number(), 3)
	manager.free()


func test_mission_3_shows_four_waves() -> void:
	var manager := ZombieManager.new()
	manager.mission_config = _config_for(Mission3Script)
	assert_eq(manager._compute_max_display_wave_number(), 4)
	manager.free()


# the tank should only ever appear once, in the last displayed wave
func test_mission_3_ends_with_a_single_tank() -> void:
	var waves := _config_for(Mission3Script).waves
	var last_wave_number: int = waves[waves.size() - 1].display_wave_number
	var tank_count := 0
	for wave in waves:
		if wave.enemy_type == TANK_TYPE:
			tank_count += wave.count
			assert_eq(wave.display_wave_number, last_wave_number, "tank spawns before the final wave")
			assert_true(wave.side_spawn_only, "tank can come from the top or bottom")
			assert_eq(wave.allowed_buckets, [3, 4] as Array[int], "tank should only get long words")
	assert_eq(tank_count, 1)


# first pass boss numbers, tougher than every normal enemy
func test_tank_is_tougher_than_the_brute() -> void:
	assert_gt(TANK_TYPE.health, BRUTE_TYPE.health)
	assert_gt(TANK_TYPE.wall_damage, BRUTE_TYPE.wall_damage)
	assert_lt(TANK_TYPE.speed, BRUTE_TYPE.speed)
	assert_eq(TANK_TYPE.word_pool_tag, "long")
