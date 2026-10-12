extends GutTest

# bullets pass through corpses that are still playing their death animation

const ProjectileScript := preload("res://scripts/entities/projectile.gd")
const ZOMBIE_SCENE := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

var wall: Node2D


func before_each() -> void:
	wall = Node2D.new()
	add_child_autofree(wall)


func _make_zombie() -> Zombie:
	var zombie: Zombie = ZOMBIE_SCENE.instantiate()
	add_child_autofree(zombie)
	zombie.setup(WALKER_TYPE, wall)
	return zombie


func _make_projectile() -> Area2D:
	var projectile: Area2D = ProjectileScript.new()
	add_child_autofree(projectile)
	return projectile


func test_bullet_hits_a_live_zombie_and_stops() -> void:
	var zombie := _make_zombie()
	var projectile := _make_projectile()
	var before := zombie.health
	projectile._try_damage_target(zombie)
	assert_lt(zombie.health, before)
	assert_true(projectile.is_queued_for_deletion())


func test_bullet_flies_through_a_dying_zombie() -> void:
	var zombie := _make_zombie()
	zombie.take_damage(9999.0)
	var projectile := _make_projectile()
	projectile._try_damage_target(zombie)
	assert_false(projectile.is_queued_for_deletion())
