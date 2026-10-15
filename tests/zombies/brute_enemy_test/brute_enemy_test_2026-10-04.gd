extends Node2D

@onready var wall_target: Marker2D = $WallTarget
@onready var status_timer: Timer = $StatusTimer
@onready var ammo_system: AmmoSystem = $World/AmmoSystem
@onready var projectile_container: Node2D = $World/ProjectileContainer
@onready var weapon_controller: WeaponController = $World/WeaponController

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const BRUTE_TYPE: EnemyTypeDef = preload("res://resources/enemies/brute.tres")

var brute: Zombie
var walker: Zombie

func _ready() -> void:
	_setup_weapon()
	_spawn_test_zombies()
	status_timer.timeout.connect(_on_status_timer_timeout)
	print("Brute enemy test ready.")
	print("Click: fire | Space: damage Brute by 25 | Enter: kill Brute | R: reset Brute")

func _setup_weapon() -> void:
	ammo_system.add_ammunition(999)
	weapon_controller.configure(ammo_system, projectile_container)

func _spawn_test_zombies() -> void:
	walker = _spawn_zombie(WALKER_TYPE, Vector2(500, 320))
	brute = _spawn_zombie(BRUTE_TYPE, Vector2(700, 320))
	print("Walker speed: ", walker.get_movement_speed())
	print("Brute speed: ", brute.get_movement_speed())
	print("Brute health: ", brute.health, "/", brute.get_max_health())

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
			if is_instance_valid(brute) and brute.current_state != Zombie.State.DEAD:
				brute.take_damage(25.0)
				print("Brute damaged: ", brute.health, "/", brute.get_max_health())
		KEY_ENTER:
			if is_instance_valid(brute) and brute.current_state != Zombie.State.DEAD:
				brute.take_damage(9999.0)
				print("Brute killed. State: ", Zombie.State.keys()[brute.current_state])
		KEY_R:
			if is_instance_valid(brute) and brute.current_state != Zombie.State.DEAD:
				brute.health = brute.get_max_health()
				print("Brute reset: ", brute.health, "/", brute.get_max_health())

func _on_status_timer_timeout() -> void:
	if not is_instance_valid(brute):
		return
	print(
		"Status | Brute: ",
		brute.health,
		"/",
		brute.get_max_health(),
		" HP | speed: ",
		brute.get_movement_speed(),
		" | state: ",
		Zombie.State.keys()[brute.current_state]
	)
