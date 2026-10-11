extends GutTest

# zombie health, death, healing, pooled reset and the medic support behaviour

const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")
const RUNNER_TYPE: EnemyTypeDef = preload("res://resources/enemies/runner.tres")
const TANK_TYPE: EnemyTypeDef = preload("res://resources/enemies/tank.tres")

var wall: Node2D


func before_each() -> void:
	# far away so nothing reaches the wall during a test
	wall = Node2D.new()
	wall.global_position = Vector2(5000, 0)
	add_child_autofree(wall)


func _spawn(type: EnemyTypeDef, at: Vector2) -> Zombie:
	var zombie: Zombie = ZombieScene.instantiate()
	zombie.is_pooled = true
	add_child_autofree(zombie)
	zombie.setup(type, wall)
	zombie.global_position = at
	return zombie


func test_setup_starts_at_full_health_and_approaching() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	assert_eq(zombie.health, WALKER_TYPE.health)
	assert_eq(zombie.current_state, Zombie.State.APPROACH)


func test_non_lethal_damage_lowers_health_and_emits_damaged() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	watch_signals(zombie)

	var killed := zombie.take_damage(10.0)

	assert_false(killed)
	assert_eq(zombie.health, WALKER_TYPE.health - 10.0)
	assert_signal_emitted(zombie, "damaged")


func test_lethal_damage_kills_and_emits_died() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	watch_signals(zombie)

	var killed := zombie.take_damage(WALKER_TYPE.health)

	assert_true(killed)
	assert_eq(zombie.current_state, Zombie.State.DEAD)
	assert_signal_emitted(zombie, "died")


func test_dead_zombie_ignores_further_damage() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	zombie.take_damage(9999.0)
	assert_false(zombie.take_damage(10.0))


func test_heal_is_capped_at_max_health() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	zombie.take_damage(5.0)

	var healed := zombie.heal(50.0)

	assert_eq(healed, 5.0)
	assert_eq(zombie.health, zombie.get_max_health())


func test_dead_zombie_cannot_be_healed() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	zombie.take_damage(9999.0)
	assert_eq(zombie.heal(10.0), 0.0)


# pooled zombies are reused, a new life must not inherit damage or death
func test_pool_reuse_restores_health_and_state() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	zombie.take_damage(9999.0)

	zombie.setup(WALKER_TYPE, wall)

	assert_eq(zombie.health, WALKER_TYPE.health)
	assert_eq(zombie.current_state, Zombie.State.APPROACH)
	assert_true(zombie.visible)


func test_dead_zombie_stays_in_place_while_the_death_animation_plays() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2(100, 50))
	zombie.take_damage(9999.0)

	assert_true(zombie.visible)
	assert_eq(zombie.global_position, Vector2(100, 50))
	assert_eq(zombie.animation_player.current_animation, "death")
	assert_false(zombie.word_label.visible)
	assert_true(zombie.collision_shape.disabled)


func test_death_animation_ends_by_hiding_the_pooled_zombie() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2(100, 50))
	watch_signals(zombie)
	zombie.take_damage(9999.0)

	await wait_for_signal(zombie.death_finished, 2.0)

	assert_signal_emitted(zombie, "death_finished")
	assert_false(zombie.visible)


# a zombie reused mid death must walk again and never finish the old death
func test_reused_zombie_walks_again_and_skips_the_old_death() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	watch_signals(zombie)
	zombie.take_damage(9999.0)

	zombie.setup(WALKER_TYPE, wall)
	assert_eq(zombie.animation_player.current_animation, "walk")
	assert_true(zombie.word_label.visible)

	await wait_seconds(0.8)
	assert_signal_not_emitted(zombie, "death_finished")
	assert_true(zombie.visible)


# the cat art faces left, so it flips when walking in from the left of the wall
func test_zombie_left_of_the_wall_faces_right() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	await wait_physics_frames(1)
	assert_true(zombie.zombie_sprite.flip_h)


func test_zombie_right_of_the_wall_faces_left() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2(6000, 0))
	await wait_physics_frames(1)
	assert_false(zombie.zombie_sprite.flip_h)


func test_runner_uses_the_dog_art() -> void:
	var zombie := _spawn(RUNNER_TYPE, Vector2.ZERO)
	assert_eq(zombie.animation_player.current_animation, "dog_walk")
	assert_true(zombie.zombie_sprite.texture.resource_path.ends_with("zombie_dog_sheet.png"))
	assert_eq(zombie.zombie_sprite.hframes, 11)


# the dog art faces right, so it only flips when walking in from the right
func test_dog_left_of_the_wall_faces_right_without_flipping() -> void:
	var zombie := _spawn(RUNNER_TYPE, Vector2.ZERO)
	await wait_physics_frames(1)
	assert_false(zombie.zombie_sprite.flip_h)


func test_dog_right_of_the_wall_flips_to_face_left() -> void:
	var zombie := _spawn(RUNNER_TYPE, Vector2(6000, 0))
	await wait_physics_frames(1)
	assert_true(zombie.zombie_sprite.flip_h)


# pooled zombies are shared by every type, a dog reused as a walker must become a cat
func test_reused_dog_switches_back_to_the_cat_art() -> void:
	var zombie := _spawn(RUNNER_TYPE, Vector2.ZERO)
	zombie.setup(WALKER_TYPE, wall)
	assert_eq(zombie.animation_player.current_animation, "walk")
	assert_true(zombie.zombie_sprite.texture.resource_path.ends_with("zombie_cat_sheet.png"))
	assert_eq(zombie.zombie_sprite.hframes, 16)


func test_dog_plays_its_own_death_and_finishes() -> void:
	var zombie := _spawn(RUNNER_TYPE, Vector2.ZERO)
	watch_signals(zombie)
	zombie.take_damage(9999.0)
	assert_eq(zombie.animation_player.current_animation, "dog_death")

	await wait_for_signal(zombie.death_finished, 2.0)
	assert_signal_emitted(zombie, "death_finished")


# the boss is the normal cat, just twice as big and untinted
func test_tank_is_a_bigger_plain_cat() -> void:
	var zombie := _spawn(TANK_TYPE, Vector2.ZERO)
	assert_eq(zombie.animation_player.current_animation, "walk")
	assert_eq(zombie.zombie_sprite.scale, Vector2(4, 4))
	assert_eq(zombie.zombie_sprite.modulate, Color.WHITE)


# cat sprite is set to double size in zombie.tscn and must survive setup()
func test_sprite_keeps_scene_scale_times_silhouette_scale() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	assert_eq(zombie.zombie_sprite.scale, Vector2(2, 2) * WALKER_TYPE.silhouette_scale)


func test_medic_heals_a_damaged_zombie_nearby() -> void:
	var walker := _spawn(WALKER_TYPE, Vector2(60, 0))
	_spawn(MEDIC_TYPE, Vector2.ZERO)
	walker.take_damage(20.0)
	# skip the heal delay so the test doesn't wait two real seconds
	walker.seconds_since_damaged = MEDIC_TYPE.heal_delay
	var damaged_health := walker.health

	await wait_seconds(0.5)

	assert_gt(walker.health, damaged_health)


func test_medic_waits_before_healing_a_freshly_hit_zombie() -> void:
	var walker := _spawn(WALKER_TYPE, Vector2(60, 0))
	_spawn(MEDIC_TYPE, Vector2.ZERO)
	walker.take_damage(20.0)
	var damaged_health := walker.health

	await wait_seconds(0.5)

	assert_eq(walker.health, damaged_health)


# three shots at the base fire rate take 1s, the medic must not heal in between
func test_heal_delay_is_longer_than_a_three_shot_burst() -> void:
	assert_gt(MEDIC_TYPE.heal_delay, 1.0)


func test_damage_resets_the_heal_timer() -> void:
	var walker := _spawn(WALKER_TYPE, Vector2.ZERO)
	assert_eq(walker.seconds_since_damaged, INF)
	walker.take_damage(5.0)
	assert_eq(walker.seconds_since_damaged, 0.0)


func test_medic_ignores_zombies_outside_its_radius() -> void:
	var walker := _spawn(WALKER_TYPE, Vector2(0, MEDIC_TYPE.support_radius * 3.0))
	_spawn(MEDIC_TYPE, Vector2.ZERO)
	walker.take_damage(20.0)
	var damaged_health := walker.health

	await wait_seconds(0.3)

	assert_eq(walker.health, damaged_health)
