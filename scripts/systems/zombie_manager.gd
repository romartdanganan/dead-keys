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
var _pool: ZombiePool

func _ready() -> void:
	_pool = ZombiePool.new(zombie_scene, self)


func start_mission() -> void:
	_wave_index = 0
	_running = true
	_run_next_wave()

func _run_next_wave() -> void:
	if not _running:
		return
	
	if mission_config == null:
		push_warning("ZombieManager: no mission config assigned")
		_running = false
		return
	
	if _wave_index >= mission_config.waves.size():
		await _wait_for_all_zombies_to_clear()
		if _running:
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
		if i < wave.count - 1 and wave.spawn_interval > 0.0:
			await get_tree().create_timer(wave.spawn_interval).timeout
	await _wait_for_all_zombies_to_clear()
	_run_next_wave()

func _wait_for_all_zombies_to_clear() -> void:
	while _running and not active_zombies.is_empty():
		await get_tree().process_frame

func _spawn_zombie(type: EnemyTypeDef) -> void:
	if spawn_points.is_empty():
		push_warning("ZombieManager: no spawn points assigned")
		return
	var zombie: Zombie = _pool.acquire()
	var spawn_point: Marker2D = spawn_points[randi() % spawn_points.size()]
	zombie.global_position = spawn_point.global_position
	zombie.is_pooled = true
	if not zombie.died.is_connected(_on_zombie_died):
		zombie.died.connect(_on_zombie_died)
	zombie.setup(type, wall_target)
	active_zombies.append(zombie)
	zombie_spawned.emit(zombie)

func _on_zombie_died(zombie: Zombie) -> void:
	active_zombies.erase(zombie)
	_pool.release(zombie)
 
func stop_mission() -> void:
	_running = false
