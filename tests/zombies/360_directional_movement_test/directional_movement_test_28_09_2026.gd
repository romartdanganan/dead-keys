extends Node2D

const ZOMBIE_SCENE := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const RUNNER_TYPE: EnemyTypeDef = preload("res://resources/enemies/runner.tres")

const ARENA_CENTER := Vector2(640.0, 360.0)
const RUNNER_WAVE_DELAY: float = 4.0
var spawn_positions: Array[Vector2] = [
	Vector2(640.0, -96.0),
	Vector2(1376.0, 360.0),
	Vector2(640.0, 816.0),
	Vector2(-96.0, 360.0),
	Vector2(1376.0, -96.0),
	Vector2(1376.0, 816.0),
	Vector2(-96.0, 816.0),
	Vector2(-96.0, -96.0),
]

@onready var arena_center: Marker2D = $ArenaCenter

var zombies: Array[Zombie] = []


func _ready() -> void:
	arena_center.global_position = ARENA_CENTER
	_spawn_test_wave(WALKER_TYPE)
	await get_tree().create_timer(RUNNER_WAVE_DELAY).timeout
	_spawn_test_wave(RUNNER_TYPE)


func _spawn_test_wave(enemy_type: EnemyTypeDef) -> void:
	for spawn_position: Vector2 in spawn_positions:
		var zombie := ZOMBIE_SCENE.instantiate() as Zombie
		add_child(zombie)
		zombie.global_position = spawn_position
		zombie.setup(enemy_type, arena_center)
		zombies.append(zombie)
