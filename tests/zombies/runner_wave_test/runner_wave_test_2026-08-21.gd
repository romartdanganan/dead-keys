extends Node2D

@export var walker_enemy_type: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
@export var runner_enemy_type: EnemyTypeDef = preload("res://resources/enemies/runner.tres")

@onready var spawn_points: Array[Marker2D] = [$World/SpawnPointLeft, $World/SpawnPointRight]
@onready var wall_target: Marker2D = $World/WallTarget
@onready var status_timer: Timer = $StatusTimer
@onready var ammo_system: AmmoSystem = $World/AmmoSystem
@onready var projectile_container: Node2D = $World/ProjectileContainer
@onready var weapon_controller: WeaponController = $World/WeaponController
@onready var typing_controller: Node = $TypingController

const TypingControllerScript: Script = preload("res://scripts/typing/typing_controller.gd")

var zombie_manager: ZombieManager
var wall_health: float = 100.0


func _ready() -> void:
	_setup_weapon()
	_setup_typing()
	_start_mission()
	status_timer.timeout.connect(_on_status_timer_timeout)
	print("Runner wave test ready. Type Walker and Runner words, then shoot them before they reach the wall.")


func _setup_weapon() -> void:
	ammo_system.add_ammunition(24)
	weapon_controller.configure(ammo_system, projectile_container)
	weapon_controller.attempted_fire_without_ammunition.connect(_on_attempted_fire_without_ammunition)


func _setup_typing() -> void:
	if typing_controller == null:
		typing_controller = TypingControllerScript.new()
		add_child(typing_controller)


func _start_mission() -> void:

	var runner_wave := WaveEntry.new()
	runner_wave.enemy_type = runner_enemy_type
	runner_wave.count = 3
	runner_wave.spawn_interval = 1.0
	runner_wave.start_delay = 0.5

	var mission := MissionConfigDef.new()
	mission.mission_id = "runner_wave_test"
	mission.mission_name = "Runner Test"
	mission.waves = [runner_wave]
	mission.base_coin_reward = 50

	zombie_manager = ZombieManager.new()
	add_child(zombie_manager)
	zombie_manager.mission_config = mission
	zombie_manager.wall_target = wall_target
	zombie_manager.spawn_points = spawn_points
	zombie_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)
	zombie_manager.start_mission()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		weapon_controller.try_fire(get_global_mouse_position())


func _on_status_timer_timeout() -> void:
	print("Active zombies: ", zombie_manager.active_zombies.size(), " | Wall health: ", wall_health)


func _on_all_waves_cleared() -> void:
	print("Runner test complete. All waves cleared.")


func _on_zombie_spawned(spawned_zombie: Zombie) -> void:
	var word_label: RichTextLabel = spawned_zombie.get_node("WordLabel")
	typing_controller.register_target(spawned_zombie, word_label)

	spawned_zombie.died.connect(
		func(dead_zombie: Zombie) -> void:
			typing_controller.unregister_target(dead_zombie)
	)
	spawned_zombie.damaged.connect(_on_zombie_damaged)
	spawned_zombie.wall_hit.connect(_on_wall_hit)


func _on_attempted_fire_without_ammunition() -> void:
	print("Cannot fire: ammunition is empty")


func _on_zombie_damaged(damaged_zombie: Zombie) -> void:
	print("Zombie health now: ", damaged_zombie.health)


func _on_wall_hit(damage: float) -> void:
	wall_health = maxf(wall_health - damage, 0.0)
	print("Wall hit for ", damage, " damage. Wall health: ", wall_health)
	if wall_health <= 0.0:
		print("Wall reached during runner test.")
