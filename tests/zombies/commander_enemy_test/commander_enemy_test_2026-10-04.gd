extends Node2D

@onready var wall_target: Marker2D = $WallTarget
@onready var status_timer: Timer = $StatusTimer
@onready var ammo_system: AmmoSystem = $World/AmmoSystem
@onready var projectile_container: Node2D = $World/ProjectileContainer
@onready var weapon_controller: WeaponController = $World/WeaponController

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const COMMANDER_TYPE: EnemyTypeDef = preload("res://resources/enemies/commander.tres")

var walker: Zombie
var commander: Zombie

func _ready() -> void:
	_setup_weapon()
	_spawn_test_zombies()
	status_timer.timeout.connect(_on_status_timer_timeout)
	print("Commander enemy test ready.")
	print("Click: fire | Space: kill Commander | R: reset Commander")

func _setup_weapon() -> void:
	ammo_system.add_ammunition(999)
	weapon_controller.configure(ammo_system, projectile_container)

func _spawn_test_zombies() -> void:
	var walker_type := WALKER_TYPE.duplicate() as EnemyTypeDef
	walker_type.speed = WALKER_TYPE.speed
	walker = _spawn_zombie(walker_type, Vector2(500, 320))

	var commander_type := COMMANDER_TYPE.duplicate() as EnemyTypeDef
	commander_type.speed = 0.0
	commander = _spawn_zombie(commander_type, Vector2(650, 320))

	print("Walker base speed: ", walker_type.speed)
	print("Walker buffed speed: ", walker.get_movement_speed())
	print("Commander radius: ", commander_type.support_radius)
	print("Commander state: ", Zombie.State.keys()[commander.current_state])

func _spawn_zombie(type: EnemyTypeDef, position: Vector2) -> Zombie:
	var spawned_zombie := ZOMBIE_SCENE.instantiate() as Zombie
	add_child(spawned_zombie)
	spawned_zombie.global_position = position
	spawned_zombie.setup(type, wall_target)
	return spawned_zombie

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		weapon_controller.try_fire(get_global_mouse_position())
		return

	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_SPACE:
			if is_instance_valid(commander) and commander.current_state != Zombie.State.DEAD:
				commander.take_damage(9999.0)
				print("Commander killed. Walker speed is now: ", walker.get_movement_speed())
		KEY_R:
			if is_instance_valid(commander) and commander.current_state != Zombie.State.DEAD:
				commander.health = commander.get_max_health()
				print("Commander reset: ", commander.health, "/", commander.get_max_health())

func _on_status_timer_timeout() -> void:
	if not is_instance_valid(walker) or not is_instance_valid(commander):
		return
	print(
		"Status | Walker speed: ",
		walker.get_movement_speed(),
		" | Commander state: ",
		Zombie.State.keys()[commander.current_state],
		" | Commander alive: ",
		commander.current_state != Zombie.State.DEAD
	)
