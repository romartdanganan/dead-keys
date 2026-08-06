extends Node2D

@export var enemy_type: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var wall_target: Marker2D = $WallTarget

const TypingControllerScript: Script = preload("res://scripts/typing/typing_controller.gd")

var zombie_scene: PackedScene = preload("res://scenes/entities/zombie.tscn")
var projectile_scene: PackedScene = preload("res://scenes/entities/projectile.tscn")

var zombie: Zombie
var ammo_system: AmmoSystem
var weapon_controller: WeaponController
var projectile_container: Node2D
var typing_controller: Node


func _ready() -> void:
	_setup_weapon_system()
	_spawn_zombie()
	_setup_typing_controller()
	print("Zombie shoot test ready. Type the word to reload, then left-click to fire.")


func _setup_weapon_system() -> void:
	ammo_system = AmmoSystem.new()
	add_child(ammo_system)
	ammo_system.reset_ammunition()

	projectile_container = Node2D.new()
	projectile_container.name = "ProjectileContainer"
	add_child(projectile_container)

	weapon_controller = WeaponController.new()
	weapon_controller.name = "WeaponController"
	weapon_controller.position = Vector2(640, 620)
	weapon_controller.projectile_scene = projectile_scene

	var muzzle_point := Marker2D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector2(0, -30)
	weapon_controller.add_child(muzzle_point)

	add_child(weapon_controller)
	weapon_controller.configure(ammo_system, projectile_container)
	weapon_controller.attempted_fire_without_ammunition.connect(
		_on_attempted_fire_without_ammunition
	)


func _spawn_zombie() -> void:
	var test_enemy_type: EnemyTypeDef = enemy_type.duplicate() as EnemyTypeDef
	test_enemy_type.health = 1.0

	zombie = zombie_scene.instantiate()
	add_child(zombie)
	zombie.global_position = spawn_point.global_position
	zombie.collision_layer = 4
	zombie.setup(test_enemy_type, wall_target)
	zombie.wall_hit.connect(_on_wall_hit)
	zombie.died.connect(_on_zombie_died)
	print("Zombie spawned. State: ", zombie.current_state, " | Health: ", zombie.health, " | Speed: ", test_enemy_type.speed)
	

func _setup_typing_controller() -> void:
	var word_label: RichTextLabel = zombie.get_node("WordLabel")
	typing_controller = TypingControllerScript.new()
	typing_controller.word_label = word_label
	add_child(typing_controller)
	typing_controller.word_completed.connect(_on_typing_word_completed)
	print("Type the word shown above the zombie's head.")


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		weapon_controller.try_fire(get_global_mouse_position())


func _on_attempted_fire_without_ammunition() -> void:
	print("Cannot fire: ammunition is empty")


func _on_typing_word_completed(word: String, ammunition_reward: int) -> void:
	var amount_added := ammo_system.add_ammunition(ammunition_reward)

	print(
		"Completed word: ",
		word,
		" | Ammunition added: ",
		amount_added
	)


func _on_wall_hit(damage: float) -> void:
	print("Wall hit for ", damage, " damage")


func _on_zombie_damaged() -> void:
	print("Zombie health now: ", zombie.health)


func _on_zombie_died(_dead_zombie: Zombie) -> void:
	print("Zombie died")
