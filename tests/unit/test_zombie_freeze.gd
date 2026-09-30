extends GutTest

# Freeze Round ability (#37): unit tests for Zombie's own freeze state
# machine (apply_freeze / auto-revert / no-stack / pooled-reuse safety).
# The hit-detection and radius-targeting side of the ability (WeaponController
# and Projectile) is covered by manual testing instead, same as Ricochet
# and Piercing Shot before it.

const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

var zombie: Zombie
var wall: Node2D


func before_each() -> void:
	wall = Node2D.new()
	wall.global_position = Vector2(1000, 0)
	add_child_autofree(wall)

	zombie = ZombieScene.instantiate()
	zombie.is_pooled = true
	add_child_autofree(zombie)
	zombie.setup(WALKER_TYPE, wall)


func test_apply_freeze_enters_frozen_state_and_stops_movement() -> void:
	zombie.apply_freeze(1.0)

	assert_eq(zombie.current_state, Zombie.State.FROZEN)
	assert_eq(zombie.velocity, Vector2.ZERO)


func test_apply_freeze_tints_the_sprite_so_it_reads_as_frozen() -> void:
	zombie.apply_freeze(1.0)

	assert_eq(zombie.sprite.modulate, zombie.FROZEN_TINT)


func test_freeze_reverts_to_approach_after_duration() -> void:
	zombie.apply_freeze(0.05)
	await wait_seconds(0.15)

	assert_eq(zombie.current_state, Zombie.State.APPROACH)
	assert_eq(zombie.sprite.modulate, Color.WHITE)


func test_freeze_resumes_attack_if_zombie_was_attacking() -> void:
	# forces ATTACK directly rather than walking the zombie to the wall,
	# only the state matters here, not how it got there
	zombie._enter_state(Zombie.State.ATTACK)
	zombie.apply_freeze(0.05)
	assert_eq(zombie.current_state, Zombie.State.FROZEN)

	await wait_seconds(0.15)

	assert_eq(zombie.current_state, Zombie.State.ATTACK)


func test_reapplying_freeze_refreshes_duration_instead_of_stacking() -> void:
	zombie.apply_freeze(0.05)
	await wait_seconds(0.02)
	zombie.apply_freeze(0.3)
	await wait_seconds(0.1)

	# original 0.05s freeze would have expired by now, the refreshed one hasn't
	assert_eq(zombie.current_state, Zombie.State.FROZEN)


func test_dead_zombie_cannot_be_frozen() -> void:
	zombie.take_damage(9999.0)
	assert_eq(zombie.current_state, Zombie.State.DEAD)

	zombie.apply_freeze(1.0)

	assert_eq(zombie.current_state, Zombie.State.DEAD)


func test_pool_reuse_clears_a_leftover_freeze() -> void:
	zombie.apply_freeze(5.0)
	assert_eq(zombie.current_state, Zombie.State.FROZEN)

	# simulates ZombieManager reacquiring this pooled instance for a new life
	zombie.setup(WALKER_TYPE, wall)

	assert_eq(zombie.current_state, Zombie.State.APPROACH)
	assert_eq(zombie.sprite.modulate, Color.WHITE)
