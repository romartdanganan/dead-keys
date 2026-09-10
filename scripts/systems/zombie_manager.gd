# TO DO

extends Node2D
class_name ZombieManager

signal all_waves_cleared
signal zombie_spawned(zombie: Zombie)
signal wave_started(wave_number: int, is_final_wave: bool)

@export var mission_config: MissionConfigDef
@export var wall_target: Node2D
@export var spawn_points: Array[Marker2D] = []

var zombie_scene: PackedScene = preload("res://scenes/entities/zombie.tscn")
var active_zombies: Array[Zombie] = []

var _wave_index: int = 0
var _running: bool = false
var _pool: ZombiePool
var _last_announced_wave_number: int = -1
var _max_display_wave_number: int = 0

func _ready() -> void:
	_pool = ZombiePool.new(zombie_scene, self)


func start_mission() -> void:
	_wave_index = 0
	_last_announced_wave_number = -1
	_max_display_wave_number = _compute_max_display_wave_number()
	_running = true
	_run_next_wave()

# figures out the highest "WAVE N" the player will see across the whole
# mission, so the last one announced can read "FINAL WAVE" instead. works
# for any mission_config, not just Mission 1's, since grouped WaveEntry rows
# (see WaveEntry.display_wave_number) are accounted for the same way they
# are at spawn time
func _compute_max_display_wave_number() -> int:
	if mission_config == null:
		return 0
	var highest := 0
	for index in mission_config.waves.size():
		var entry: WaveEntry = mission_config.waves[index]
		var effective_number: int = entry.display_wave_number if entry.display_wave_number > 0 else index + 1
		highest = max(highest, effective_number)
	return highest

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
		# process_always=false so this respects the Pause menu (#44) instead
		# of ticking down while gameplay is paused
		await get_tree().create_timer(wave.start_delay, false).timeout

	# groups multiple WaveEntry rows under one announcement when display_wave_number
	# is set, otherwise every entry announces its own position (see WaveEntry)
	var display_number: int = wave.display_wave_number if wave.display_wave_number > 0 else _wave_index
	if display_number != _last_announced_wave_number:
		_last_announced_wave_number = display_number
		wave_started.emit(display_number, display_number == _max_display_wave_number)

	for i in wave.count:
		if not _running:
			return
		_spawn_zombie(wave.enemy_type)
		if i < wave.count - 1 and wave.spawn_interval > 0.0:
			await get_tree().create_timer(wave.spawn_interval, false).timeout
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
	# small random offset so zombies reusing the same spawn point don't walk
	# the exact same line and visually stack on top of each other, since
	# there's no separation/flocking behaviour between zombies yet (GDD §8.1)
	var spawn_jitter := Vector2(randf_range(-35.0, 35.0), randf_range(-15.0, 15.0))
	zombie.global_position = spawn_point.global_position + spawn_jitter
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
