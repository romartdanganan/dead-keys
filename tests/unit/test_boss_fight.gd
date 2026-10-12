extends GutTest

# tank boss fight: entrance, phase changes, summoned cats and dogs, armour crack, finale cinematic

const BossFight := preload("res://scripts/missions/boss_fight.gd")
const TANK_TYPE: EnemyTypeDef = preload("res://resources/enemies/tank.tres")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const RUNNER_TYPE: EnemyTypeDef = preload("res://resources/enemies/runner.tres")

var manager: ZombieManager
var wall: Node2D
var fight: Node


func before_each() -> void:
	wall = Node2D.new()
	wall.global_position = Vector2(640, 360)
	add_child_autofree(wall)
	manager = ZombieManager.new()
	manager.wall_target = wall
	add_child_autofree(manager)
	fight = BossFight.new()
	add_child_autofree(fight)
	fight.setup(manager)


func after_each() -> void:
	Engine.time_scale = 1.0


func _spawn_tank() -> Zombie:
	return manager.spawn_extra(TANK_TYPE, Vector2(200, 360))


func _damage_to(zombie: Zombie, fraction: float) -> void:
	zombie.take_damage(zombie.health - zombie.get_max_health() * fraction)


func test_tank_spawn_starts_the_fight() -> void:
	var tank := _spawn_tank()
	assert_eq(fight.boss, tank)
	assert_eq(fight.phase, 1)


func test_normal_zombies_do_not_start_a_fight() -> void:
	manager.spawn_extra(WALKER_TYPE, Vector2(200, 360))
	assert_null(fight.boss)
	assert_eq(fight.phase, 0)


func test_tank_gets_its_own_copy_of_its_stats() -> void:
	var tank := _spawn_tank()
	assert_ne(tank.enemy_type, TANK_TYPE)
	assert_eq(tank.enemy_type.enemy_id, "tank")


# summons wait for the end of the frame, so they are never made inside a bullet hit
func test_phase_2_summons_cats_with_short_words() -> void:
	var tank := _spawn_tank()
	var before := manager.active_zombies.size()
	_damage_to(tank, 0.6)
	assert_eq(fight.phase, 2)
	await wait_physics_frames(2)
	assert_eq(manager.active_zombies.size(), before + BossFight.SUMMON_COUNT)
	for zombie in manager.active_zombies:
		if zombie != tank:
			assert_eq(zombie.enemy_type, WALKER_TYPE)
			assert_eq(zombie.allowed_buckets, BossFight.SUMMON_BUCKETS)


func test_phase_3_summons_dogs() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	await wait_physics_frames(2)
	_damage_to(tank, 0.3)
	await wait_physics_frames(2)
	var dogs := manager.active_zombies.filter(func(zombie: Zombie) -> bool: return zombie.enemy_type == RUNNER_TYPE)
	assert_eq(dogs.size(), BossFight.SUMMON_COUNT)


# summoned helpers must get a working hitbox or bullets fly straight through them
func test_summoned_helpers_can_be_hit() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	await wait_physics_frames(2)
	for zombie in manager.active_zombies:
		assert_false(zombie.collision_shape.disabled)


func test_phase_change_staggers_the_tank() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	assert_eq(tank.get_movement_speed(), 0.0)
	fight._process(BossFight.STAGGER_SECONDS + 0.1)
	assert_gt(tank.get_movement_speed(), 0.0)


func test_phase_3_cracks_the_armour_and_enrages() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	_damage_to(tank, 0.3)
	assert_eq(fight.phase, 3)
	assert_almost_eq(tank.health, tank.get_max_health() * 0.3 * (1.0 - BossFight.ARMOUR_CRACK_SHARE), 0.01)
	fight._process(BossFight.STAGGER_SECONDS + 0.1)
	assert_almost_eq(tank.enemy_type.speed, TANK_TYPE.speed * BossFight.ENRAGED_SPEED_MULTIPLIER, 0.01)


func test_enrage_never_changes_the_shared_tank_file() -> void:
	var original_speed := TANK_TYPE.speed
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	_damage_to(tank, 0.3)
	fight._process(BossFight.STAGGER_SECONDS + 0.1)
	assert_eq(TANK_TYPE.speed, original_speed)


# a big hit skips straight past both marks, the phases still run one at a time
func test_phases_only_move_forward_one_at_a_time() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.2)
	assert_eq(fight.phase, 2)
	tank.heal(9999.0)
	tank.take_damage(1.0)
	assert_eq(fight.phase, 2)


# endless keeps going after a boss, so it only gets a short slow motion
func test_boss_death_without_ending_the_mission_plays_quick_slow_motion() -> void:
	fight.ends_mission = false
	var tank := _spawn_tank()
	tank.take_damage(99999.0)
	assert_eq(fight.phase, 4)
	assert_almost_eq(Engine.time_scale, BossFight.SLOW_MOTION_SCALE, 0.001)
	# delta is in game time, so this is a full real second
	fight._process(BossFight.SLOW_MOTION_SCALE * 1.0)
	assert_eq(Engine.time_scale, 1.0)


func test_leaving_mid_finale_restores_time() -> void:
	var tank := _spawn_tank()
	tank.take_damage(99999.0)
	fight.free()
	assert_eq(Engine.time_scale, 1.0)
	fight = null


func test_boss_kill_stops_new_spawns() -> void:
	var tank := _spawn_tank()
	manager._running = true
	tank.take_damage(99999.0)
	assert_true(fight.finale_playing)
	assert_false(manager._running)


# the tank dies first in slow motion, the rest drop together once the camera zooms out
func test_finale_kills_every_zombie_then_finishes() -> void:
	var tank := _spawn_tank()
	var walker := manager.spawn_extra(WALKER_TYPE, Vector2(900, 360))
	watch_signals(fight)
	tank.take_damage(99999.0)
	assert_almost_eq(Engine.time_scale, BossFight.SLOW_MOTION_SCALE, 0.001)
	assert_ne(walker.current_state, Zombie.State.DEAD)
	assert_false(walker.word_label.visible)
	# game time deltas, divided by the slow motion scale they become the real seconds
	fight._process(BossFight.FINALE_SLOW_SECONDS * BossFight.SLOW_MOTION_SCALE + 0.01)
	assert_eq(walker.current_state, Zombie.State.DEAD)
	assert_eq(Engine.time_scale, 1.0)
	assert_signal_not_emitted(fight, "finale_finished")
	fight._process(BossFight.FINALE_ZOOM_OUT_SECONDS + BossFight.FINALE_HOLD_SECONDS + 0.01)
	assert_signal_emitted(fight, "finale_finished")
	assert_eq(walker.current_state, Zombie.State.DEAD)
	assert_eq(Engine.time_scale, 1.0)
	assert_false(fight.finale_playing)


# a tank already hitting the ring, standing on its left edge
func _spawn_tank_at_the_ring() -> Zombie:
	var tank := manager.spawn_extra(TANK_TYPE, wall.global_position + Vector2(-manager.wall_contact_radius, 0))
	tank._enter_state(Zombie.State.ATTACK)
	return tank


func _distance_to_base(zombie: Zombie) -> float:
	return zombie.global_position.distance_to(wall.global_position)


# the roar shoves a tank at the wall back out, so it can't keep hitting the wall through its stagger
func test_roar_pushes_a_tank_at_the_ring_to_a_safe_distance() -> void:
	var tank := _spawn_tank_at_the_ring()
	_damage_to(tank, 0.6)
	assert_eq(tank.current_state, Zombie.State.APPROACH)
	# one physics step longer than the slide finishes the whole knockback
	tank._physics_process(Zombie.KNOCKBACK_DURATION + 0.01)
	assert_almost_eq(_distance_to_base(tank), manager.wall_contact_radius + BossFight.SAFE_DISTANCE_PAST_RING, 0.5)


func test_roar_leaves_a_far_away_tank_where_it_is() -> void:
	var tank := _spawn_tank()
	_damage_to(tank, 0.6)
	assert_eq(tank._knockback_remaining, 0.0)


# like the shockwave ability, zombies near the tank are blown away from the base, far ones are not
func test_roar_blows_back_zombies_near_the_tank_only() -> void:
	var tank := _spawn_tank_at_the_ring()
	var near := manager.spawn_extra(WALKER_TYPE, tank.global_position + Vector2(0, -60))
	var far := manager.spawn_extra(WALKER_TYPE, wall.global_position + Vector2(manager.wall_contact_radius + 40, 0))
	var near_before := _distance_to_base(near)
	_damage_to(tank, 0.6)
	near._physics_process(Zombie.KNOCKBACK_DURATION + 0.01)
	assert_gt(_distance_to_base(near), near_before)
	assert_eq(far._knockback_remaining, 0.0)


# helpers always land further out than the tank, so they have a walk before reaching the ring
func test_helpers_spawn_further_from_the_base_than_the_tank() -> void:
	var tank := _spawn_tank_at_the_ring()
	_damage_to(tank, 0.6)
	await wait_physics_frames(2)
	var landing := manager.wall_contact_radius + BossFight.SAFE_DISTANCE_PAST_RING
	var helpers := manager.active_zombies.filter(func(zombie: Zombie) -> bool: return zombie != tank)
	assert_eq(helpers.size(), BossFight.SUMMON_COUNT)
	for helper: Zombie in helpers:
		assert_gt(_distance_to_base(helper), landing)
