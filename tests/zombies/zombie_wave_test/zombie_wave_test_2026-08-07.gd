extends Node2D

@export var enemy_type: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
 
@onready var wall_target: Marker2D = $WallTarget
@onready var spawn_points: Array[Marker2D] = [$SpawnPoint1, $SpawnPoint2]
@onready var status_timer: Timer = $StatusTimer

const TypingControllerScript: Script = preload("res://scripts/typing/typing_controller.gd")
var zombie_manager: ZombieManager
var typing_controller: TypingController
 
func _ready() -> void:
	# Placeholder pacing, guesses to make the loop watchable 
	# TODO: Adjust numbers for real game
	typing_controller = TypingControllerScript.new()
	add_child(typing_controller)

	var wave := WaveEntry.new()
	wave.enemy_type = enemy_type
	wave.count = 5
	wave.spawn_interval = 1.5
	wave.start_delay = 0.5

	var mission := MissionConfigDef.new()
	mission.mission_id = "mission_1_wave_1_test"
	mission.mission_name = "Defend the Suburbs - Wave 1 (test)"
	mission.waves = [wave]
	mission.base_coin_reward = 50

	zombie_manager = ZombieManager.new()
	add_child(zombie_manager)

	zombie_manager.mission_config = mission
	zombie_manager.wall_target = wall_target
	zombie_manager.spawn_points = spawn_points

	zombie_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)

	status_timer.timeout.connect(_on_status_timer_timeout)

	zombie_manager.start_mission()

	print("Wave started: ", wave.count, " Walkers")
	print("Type any active word shown above a zombie.")
 
func _on_status_timer_timeout() -> void:
	print("Active zombies: ", zombie_manager.active_zombies.size())
 
func _on_all_waves_cleared() -> void:
	print("Wave cleared. All zombies spawned out")

func _on_zombie_spawned(zombie: Zombie) -> void:
	var word_label: RichTextLabel = zombie.get_node("WordLabel")
	
	typing_controller.register_target(zombie, word_label)
	
	zombie.died.connect(
		func(dead_zombie: Zombie) -> void:
			typing_controller.unregister_target(dead_zombie)
	)
 
