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


func test_spawned_zombie_emits_zombie_spawned() -> void:
	watch_signals(manager)
	_start_with_two_batches(true)
	await wait_physics_frames(2)
	assert_signal_emitted(manager, "zombie_spawned")


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
