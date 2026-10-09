extends GutTest

# zombie health, death, healing, pooled reset and the medic support behaviour

const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")

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


# placeholder sprite is set to half size in zombie.tscn and must survive setup()
func test_sprite_keeps_scene_scale_times_silhouette_scale() -> void:
	var zombie := _spawn(WALKER_TYPE, Vector2.ZERO)
	assert_eq(zombie.zombie_sprite.scale, Vector2(0.5, 0.5) * WALKER_TYPE.silhouette_scale)


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
