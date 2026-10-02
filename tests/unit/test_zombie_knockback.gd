extends GutTest

# unit tests for zombie.apply_knockback(), used by shockwave round
# hit detection and radius targeting are covered by manual testing

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


func test_knockback_moves_zombie_by_offset() -> void:
	zombie.global_position = Vector2(500, 0)

	zombie.apply_knockback(Vector2(-150, 0))

	assert_eq(zombie.global_position, Vector2(350, 0))


func test_knockback_sends_attacking_zombie_back_to_approach() -> void:
	zombie._enter_state(Zombie.State.ATTACK)

	zombie.apply_knockback(Vector2(-150, 0))

	assert_eq(zombie.current_state, Zombie.State.APPROACH)


func test_knockback_keeps_frozen_zombie_frozen() -> void:
	zombie.apply_freeze(1.0)

	zombie.apply_knockback(Vector2(-150, 0))

	assert_eq(zombie.current_state, Zombie.State.FROZEN)


func test_frozen_attacker_approaches_after_knockback_and_thaw() -> void:
	zombie._enter_state(Zombie.State.ATTACK)
	zombie.apply_freeze(0.05)
	zombie.apply_knockback(Vector2(-150, 0))

	await wait_seconds(0.15)

	assert_eq(zombie.current_state, Zombie.State.APPROACH)


func test_dead_zombie_is_not_moved_by_knockback() -> void:
	zombie.take_damage(9999.0)
	var dead_position := zombie.global_position

	zombie.apply_knockback(Vector2(-150, 0))

	assert_eq(zombie.global_position, dead_position)
	assert_eq(zombie.current_state, Zombie.State.DEAD)
