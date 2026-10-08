extends GutTest

# boss bar only appears for boss types and follows the boss's health

const BossBarScene := preload("res://scenes/ui/boss_health_bar.tscn")
const BossBarScript := preload("res://scripts/ui/boss_health_bar.gd")
const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const BRUTE_TYPE: EnemyTypeDef = preload("res://resources/enemies/brute.tres")
const TANK_TYPE: EnemyTypeDef = preload("res://resources/enemies/tank.tres")

var boss_bar: CanvasLayer
var manager: ZombieManager
var wall: Node2D


func before_each() -> void:
	manager = ZombieManager.new()
	add_child_autofree(manager)
	wall = Node2D.new()
	wall.global_position = Vector2(5000, 0)
	add_child_autofree(wall)
	boss_bar = BossBarScene.instantiate()
	add_child_autofree(boss_bar)
	boss_bar.setup(manager)


func _spawn(type: EnemyTypeDef) -> Zombie:
	var zombie: Zombie = ZombieScene.instantiate()
	zombie.is_pooled = true
	add_child_autofree(zombie)
	zombie.setup(type, wall)
	manager.zombie_spawned.emit(zombie)
	return zombie


func test_only_the_tank_counts_as_a_boss() -> void:
	assert_true(BossBarScript.is_boss(TANK_TYPE))
	assert_false(BossBarScript.is_boss(WALKER_TYPE))
	assert_false(BossBarScript.is_boss(BRUTE_TYPE))
	assert_false(BossBarScript.is_boss(null))


func test_bar_is_hidden_until_a_boss_spawns() -> void:
	assert_false(boss_bar.panel.visible)
	_spawn(WALKER_TYPE)
	assert_false(boss_bar.panel.visible)


func test_boss_spawn_shows_its_name_and_full_health() -> void:
	_spawn(TANK_TYPE)
	assert_true(boss_bar.panel.visible)
	assert_eq(boss_bar.name_label.text, "TANK")
	assert_eq(boss_bar.bar.max_value, TANK_TYPE.health)
	assert_eq(boss_bar.bar.value, TANK_TYPE.health)


func test_bar_follows_damage_to_the_boss() -> void:
	var tank := _spawn(TANK_TYPE)
	tank.take_damage(50.0)
	boss_bar._process(0.0)
	assert_eq(boss_bar.bar.value, TANK_TYPE.health - 50.0)


func test_bar_hides_when_the_boss_dies() -> void:
	var tank := _spawn(TANK_TYPE)
	tank.take_damage(TANK_TYPE.health)
	assert_false(boss_bar.panel.visible)


func test_other_zombies_dying_do_not_hide_the_bar() -> void:
	_spawn(TANK_TYPE)
	var walker := _spawn(WALKER_TYPE)
	walker.take_damage(WALKER_TYPE.health)
	assert_true(boss_bar.panel.visible)
