extends Node2D

@onready var wall_target: Marker2D = $World/WallTarget
@onready var ammo_system: AmmoSystem = $World/AmmoSystem
@onready var projectile_container: Node2D = $World/ProjectileContainer
@onready var weapon_controller: WeaponController = $World/WeaponController
@onready var status_timer: Timer = $StatusTimer

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const MEDIC_TYPE: EnemyTypeDef = preload("res://resources/enemies/medic.tres")

var walker: Zombie
var medic: Zombie


func _ready() -> void:
	_setup_weapon()
	_spawn_test_zombies()
	status_timer.timeout.connect(_on_status_timer_timeout)
	print("Medic healing test ready.")
	print("Mouse: fire | Space: damage Walker by 5 | R: reset Walker to 15/30 HP")
	print("Ammo is automatically refilled to 999.")


func _setup_weapon() -> void:
	ammo_system.add_ammunition(999)
	weapon_controller.configure(ammo_system, projectile_container)


func _spawn_test_zombies() -> void:
	var walker_type := WALKER_TYPE.duplicate() as EnemyTypeDef
	walker_type.speed = 0.0
	walker = _spawn_zombie(walker_type, Vector2(520, 320))
	walker.take_damage(15.0)

	var medic_type := MEDIC_TYPE.duplicate() as EnemyTypeDef
	medic_type.speed = 0.0
	medic = _spawn_zombie(medic_type, Vector2(650, 320))

	print("Walker starts injured at ", walker.health, "/", walker.get_max_health(), " HP.")
	print("Medic/Walker distance: ", medic.global_position.distance_to(walker.global_position), " px.")


func _spawn_zombie(type: EnemyTypeDef, position: Vector2) -> Zombie:
	var spawned_zombie := ZOMBIE_SCENE.instantiate() as Zombie
	add_child(spawned_zombie)
	spawned_zombie.global_position = position
	spawned_zombie.setup(type, wall_target)
	return spawned_zombie


func _process(_delta: float) -> void:
	# Keep firing available without typing words or changing production systems.
	ammo_system.add_ammunition(999)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		weapon_controller.try_fire(get_global_mouse_position())
		return

	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_SPACE:
			if is_instance_valid(walker) and walker.current_state != Zombie.State.DEAD:
				walker.take_damage(5.0)
				print("Test damage applied. Walker health: ", walker.health, "/", walker.get_max_health())
		KEY_R:
			if is_instance_valid(walker) and walker.current_state != Zombie.State.DEAD:
				walker.health = 15.0
				print("Walker reset to ", walker.health, "/", walker.get_max_health(), " HP.")


func _on_status_timer_timeout() -> void:
	if not is_instance_valid(walker) or not is_instance_valid(medic):
		return
	print(
		"Status | Walker: ",
		walker.health,
		"/",
		walker.get_max_health(),
		" | Medic: ",
		medic.health,
		"/",
		medic.get_max_health(),
		" | Medic state: ",
		Zombie.State.keys()[medic.current_state]
	)