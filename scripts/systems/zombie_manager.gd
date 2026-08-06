# TO DO

extends Node2D
class_name ZombieManager

signal all_waves_cleared
signal zombie_spawned(zombie: Zombie)

@export var mission_config: MissionConfigDef
@export var wall_target: Node2D
@export var spawn_points: Array[Marker2D] = []

var zombie_scene: PackedScene = preload("res://scenes/entities/zombie.tscn")
var active_zombies: Array[Zombie] = []

var _wave_index: int = 0
var _running: bool = false

func start_mission() -> void:
	_wave_index = 0
	_running = true
	_run_next_wave()

func _run_next_wave() -> void:
	if not _running:
		return
	if mission_config == null or _wave_index >= mission_config.waves.size():
		all_waves_cleared.emit()
		_running = false
		return
	
	var wave: WaveEntry = mission_config.waves[_wave_index]
	_wave_index += 1
	
	if wave.start_delay > 0.0:
		await get_tree().create_timer(wave.start_delay).timeout
	
	for i in wave.count:
		if not _running:
			return
		_spawn_zombie(wave.enemy_type)
		if i < wave.count - 1:
			await get_tree().create_timer(wave.spawn_interval).timeout
	_run_next_wave()

func _spawn_zombie(type: EnemyTypeDef) -> void:
	if spawn_points.is_empty():
		push_warning("ZombieManager: no spawn_points as signed")
		return
	var zombie: Zombie = zombie_scene.instantiate()
	add_child(zombie)
	var spawn_point: Marker2D = spawn_points[randi() % spawn_points.size()]
	zombie.global_position = spawn_point.global_position
	zombie.setup(type, wall_target)
	zombie.died.connect(_on_zombie_died)
	active_zombies.append(zombie)
	zombie_spawned.emit(zombie)

func _on_zombie_died(zombie: Zombie) -> void:
	active_zombies.erase(zombie)
 
func stop_mission() -> void:
	_running = false
