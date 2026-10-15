extends GutTest

# endless survival: round building and the top five score table

const EndlessWaves := preload("res://scripts/missions/endless_waves.gd")
const EndlessScores := preload("res://scripts/missions/endless_scores.gd")
const TEST_SAVE_PATH := "user://test_endless_scores.cfg"

var _saved_path: String


func before_each() -> void:
	_saved_path = EndlessScores.save_path
	EndlessScores.save_path = TEST_SAVE_PATH
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)
	EndlessScores.save_path = _saved_path


func _count(config: MissionConfigDef, type: EnemyTypeDef) -> int:
	var total := 0
	for wave in config.waves:
		if wave.enemy_type == type:
			total += wave.count
	return total


func _total(config: MissionConfigDef) -> int:
	var total := 0
	for wave in config.waves:
		total += wave.count
	return total


# round 1 is only three walkers with the shortest words
func test_round_1_is_a_gentle_start() -> void:
	var config := EndlessWaves.build_round(1)
	assert_eq(config.waves.size(), 1)
	assert_eq(config.waves[0].enemy_type, EndlessWaves.WALKER)
	assert_eq(config.waves[0].count, 3)
	assert_eq(config.waves[0].allowed_buckets, [1] as Array[int])


# every round adds at most a couple of zombies, so the ramp never jumps
func test_rounds_grow_slowly() -> void:
	for round_number in range(2, 21):
		var before := EndlessWaves.build_round(round_number - 1)
		var after := EndlessWaves.build_round(round_number)
		var grew := (_total(after) - _count(after, EndlessWaves.TANK)) - (_total(before) - _count(before, EndlessWaves.TANK))
		assert_lte(grew, 3, "round %d jumped by %d" % [round_number, grew])


func test_rounds_never_get_smaller() -> void:
	var previous := 0
	for round_number in range(1, 21):
		# boss tanks come and go every 5th round, so only the regular pack has to grow
		var config := EndlessWaves.build_round(round_number)
		var total := _total(config) - _count(config, EndlessWaves.TANK)
		assert_gte(total, previous, "round %d shrank" % round_number)
		previous = total


func test_enemy_types_join_over_time() -> void:
	assert_eq(_count(EndlessWaves.build_round(2), EndlessWaves.RUNNER), 0)
	assert_gt(_count(EndlessWaves.build_round(3), EndlessWaves.RUNNER), 0)
	assert_eq(_count(EndlessWaves.build_round(4), EndlessWaves.MEDIC), 0)
	assert_gt(_count(EndlessWaves.build_round(5), EndlessWaves.MEDIC), 0)
	assert_gt(_count(EndlessWaves.build_round(6), EndlessWaves.BRUTE), 0)
	assert_eq(_count(EndlessWaves.build_round(7), EndlessWaves.COMMANDER), 0)
	assert_gt(_count(EndlessWaves.build_round(8), EndlessWaves.COMMANDER), 0)


func test_every_fifth_round_has_one_tank_with_long_words() -> void:
	for round_number in range(1, 16):
		var config := EndlessWaves.build_round(round_number)
		var tanks := _count(config, EndlessWaves.TANK)
		if round_number % 5 == 0:
			assert_eq(tanks, 1, "round %d should have a tank" % round_number)
			for wave in config.waves:
				if wave.enemy_type == EndlessWaves.TANK:
					assert_true(wave.side_spawn_only)
					assert_eq(wave.allowed_buckets, [3, 4] as Array[int])
		else:
			assert_eq(tanks, 0, "round %d should not have a tank" % round_number)


func test_late_rounds_stay_capped() -> void:
	var config := EndlessWaves.build_round(60)
	assert_lte(_count(config, EndlessWaves.WALKER), EndlessWaves.MAX_WALKERS)
	assert_lte(_count(config, EndlessWaves.RUNNER), EndlessWaves.MAX_RUNNERS)
	for wave in config.waves:
		assert_gte(wave.spawn_interval, 0.0)


func test_endless_pays_no_gold() -> void:
	assert_eq(EndlessWaves.build_round(3).base_coin_reward, 0)


func test_score_counts_kills_and_rounds() -> void:
	assert_eq(EndlessScores.compute_score(12, 3), 12 * 10 + 3 * 100)


func test_empty_table_has_no_best() -> void:
	assert_eq(EndlessScores.best_score(), 0)


func test_scores_are_kept_highest_first() -> void:
	EndlessScores.submit(300, 2)
	EndlessScores.submit(900, 5)
	EndlessScores.submit(500, 3)
	var scores := EndlessScores.load_scores()
	assert_eq(scores[0]["score"], 900)
	assert_eq(scores[1]["score"], 500)
	assert_eq(scores[2]["score"], 300)
	assert_eq(EndlessScores.best_score(), 900)


func test_submit_returns_the_new_place() -> void:
	EndlessScores.submit(500, 3)
	assert_eq(EndlessScores.submit(800, 4), 1)
	assert_eq(EndlessScores.submit(100, 1), 3)


func test_table_keeps_only_the_top_five() -> void:
	for score in [100, 200, 300, 400, 500]:
		EndlessScores.submit(score, 1)
	assert_eq(EndlessScores.submit(50, 1), 0)
	assert_eq(EndlessScores.load_scores().size(), EndlessScores.MAX_ENTRIES)
	assert_eq(EndlessScores.submit(450, 1), 2)
	assert_eq(EndlessScores.load_scores().back()["score"], 200)
