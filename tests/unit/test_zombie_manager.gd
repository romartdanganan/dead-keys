extends GutTest

# wave spawning, mainly that wait_for_clear controls whether batches overlap

const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

var manager: ZombieManager
var wall: Node2D


func before_each() -> void:
	wall = Node2D.new()
	wall.global_position = Vector2(640, 360)
	add_child_autofree(wall)
	manager = ZombieManager.new()
	manager.wall_target = wall
	add_child_autofree(manager)


func after_each() -> void:
	# stop the wave coroutines before the manager is freed
	manager.stop_mission()
	await wait_physics_frames(2)


func _start_with_two_batches(first_waits: bool) -> void:
	var first := WaveEntry.new()
	first.enemy_type = WALKER_TYPE
	first.count = 1
	first.wait_for_clear = first_waits
	var second := WaveEntry.new()
	second.enemy_type = WALKER_TYPE
	second.count = 1
	var config := MissionConfigDef.new()
	config.waves = [first, second]
	manager.mission_config = config
	manager.start_mission()


func test_waiting_batch_blocks_the_next_one() -> void:
	_start_with_two_batches(true)
	await wait_physics_frames(5)
	assert_eq(manager.active_zombies.size(), 1)


func test_non_waiting_batch_lets_the_next_one_spawn() -> void:
	_start_with_two_batches(false)
	await wait_physics_frames(5)
	assert_eq(manager.active_zombies.size(), 2)


# a corpse goes back to the pool only after its death animation, so new spawns can't grab it
func test_dying_zombie_returns_to_the_pool_after_its_death_animation() -> void:
	var only := WaveEntry.new()
	only.enemy_type = WALKER_TYPE
	only.count = 1
	var config := MissionConfigDef.new()
	config.waves = [only]
	manager.mission_config = config
	manager.start_mission()
	await wait_physics_frames(2)
	var zombie: Zombie = manager.active_zombies[0]

	zombie.take_damage(9999.0)
	assert_false(manager.active_zombies.has(zombie))
	assert_eq(manager._pool.size(), 0)

	await wait_for_signal(zombie.death_finished, 2.0)
	assert_eq(manager._pool.size(), 1)


func test_spawned_zombie_emits_zombie_spawned() -> void:
	watch_signals(manager)
	_start_with_two_batches(true)
	await wait_physics_frames(2)
	assert_signal_emitted(manager, "zombie_spawned")


# every direction should start just past the screen edge, not far off on a circle
func test_spawn_position_is_just_past_the_screen_edge() -> void:
	var centre := Vector2(640, 360)
	var half := Vector2(640, 360)
	assert_almost_eq(ZombieManager.spawn_position(centre, half, 0.0, 100.0), Vector2(1380, 360), Vector2(0.01, 0.01))
	assert_almost_eq(ZombieManager.spawn_position(centre, half, PI, 100.0), Vector2(-100, 360), Vector2(0.01, 0.01))
	assert_almost_eq(ZombieManager.spawn_position(centre, half, -PI / 2.0, 100.0), Vector2(640, -100), Vector2(0.01, 0.01))
	assert_almost_eq(ZombieManager.spawn_position(centre, half, PI / 2.0, 100.0), Vector2(640, 820), Vector2(0.01, 0.01))


func test_spawn_position_is_always_off_screen() -> void:
	var centre := Vector2(640, 360)
	var half := Vector2(640, 360)
	var screen := Rect2(Vector2.ZERO, half * 2.0)
	for step in 36:
		var spawn_point := ZombieManager.spawn_position(centre, half, step * TAU / 36.0, 100.0)
		assert_false(screen.has_point(spawn_point), "spawned on screen at %s" % spawn_point)


func test_side_only_spawns_never_come_from_top_or_bottom() -> void:
	for i in 200:
		var direction := Vector2.RIGHT.rotated(ZombieManager.pick_spawn_angle(true))
		assert_true(absf(direction.x) >= cos(ZombieManager.SIDE_SPAWN_SPREAD) - 0.001, "angle too steep: %s" % direction)


func test_wave_entry_spawns_anywhere_by_default() -> void:
	assert_false(WaveEntry.new().side_spawn_only)


func test_grouped_entries_count_as_one_displayed_wave() -> void:
	var a := WaveEntry.new()
	a.display_wave_number = 1
	var b := WaveEntry.new()
	b.display_wave_number = 1
	var c := WaveEntry.new()
	var config := MissionConfigDef.new()
	config.waves = [a, b, c]
	manager.mission_config = config
	# c has no display number so it uses its position, 3
	assert_eq(manager._compute_max_display_wave_number(), 3)


# seconds a zombie of this speed needs to reach the ring from a spawn point
func _seconds_to_ring(spawn_at: Vector2, speed: float) -> float:
	var half := Vector2(640, 360)
	var scale := ZombieManager.travel_scale_for(spawn_at, wall.global_position, manager.wall_contact_radius, half)
	return (spawn_at.distance_to(wall.global_position) - manager.wall_contact_radius) / (speed * scale)


func _spawn_point(angle: float) -> Vector2:
	return ZombieManager.spawn_position(wall.global_position, Vector2(640, 360), angle, ZombieManager.SPAWN_MARGIN)


# a zombie from the bottom middle and one from the middle left arrive together
func test_every_side_reaches_the_ring_at_the_same_time() -> void:
	var from_left := _seconds_to_ring(_spawn_point(PI), WALKER_TYPE.speed)
	for angle in [0.0, PI * 0.5, PI * 1.5, PI * 0.25, PI * 1.2]:
		assert_almost_eq(_seconds_to_ring(_spawn_point(angle), WALKER_TYPE.speed), from_left, 0.01)


# a side zombie takes as long to reach the ring as it took to reach the base before the ring
func test_side_pace_matches_the_game_before_the_ring() -> void:
	var before_ring := (640.0 + ZombieManager.SPAWN_MARGIN - Zombie.WALL_CONTACT_DISTANCE) / WALKER_TYPE.speed
	assert_almost_eq(_seconds_to_ring(_spawn_point(PI), WALKER_TYPE.speed), before_ring / ZombieManager.ZOMBIE_PACE, 0.01)


func test_a_bigger_ring_does_not_change_arrival_time() -> void:
	var normal := _seconds_to_ring(_spawn_point(PI * 0.5), WALKER_TYPE.speed)
	manager.wall_contact_radius = 120.0
	assert_almost_eq(_seconds_to_ring(_spawn_point(PI * 0.5), WALKER_TYPE.speed), normal, 0.01)


func test_wave_zombies_get_their_travel_scale_and_extras_do_not() -> void:
	manager._spawn_zombie(WALKER_TYPE)
	var wave_zombie: Zombie = manager.active_zombies.back()
	var expected := ZombieManager.travel_scale_for(wave_zombie.global_position, wall.global_position, manager.wall_contact_radius, manager.get_viewport_rect().size * 0.5)
	assert_almost_eq(wave_zombie.travel_scale, expected, 0.0001)
	var extra := manager.spawn_extra(WALKER_TYPE, Vector2(500, 360))
	assert_eq(extra.travel_scale, 1.0)


# the accessibility speed setting still slows zombies on top of the travel scale
func test_travel_scale_stacks_with_the_zombie_speed_setting() -> void:
	var saved := SettingsState.zombie_speed_index
	manager._spawn_zombie(WALKER_TYPE)
	var zombie: Zombie = manager.active_zombies.back()
	zombie.travel_scale = 0.5
	SettingsState.zombie_speed_index = 1
	assert_almost_eq(zombie.get_movement_speed(), WALKER_TYPE.speed * 0.5 * SettingsState.ZOMBIE_SPEED_MULTIPLIERS[1], 0.001)
	SettingsState.zombie_speed_index = saved
