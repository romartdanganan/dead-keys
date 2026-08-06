extends Node2D

@export var enemy_type: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var wall_target: Marker2D = $WallTarget

var zombie_scene: PackedScene = preload("res://scenes/entities/zombie.tscn")
var zombie: Zombie

const TypingControllerScript: Script = preload("res://scripts/typing/typing_controller.gd")
var typing_controller: Node

func _ready() -> void:
	zombie = zombie_scene.instantiate()
	add_child(zombie)
	zombie.global_position = spawn_point.global_position
	zombie.setup(enemy_type, wall_target)
	zombie.wall_hit.connect(_on_wall_hit)
	zombie.died.connect(_on_zombie_died)
	print("Zombie spawned. State: ", zombie.current_state)
	
	var word_label: RichTextLabel = zombie.get_node("WordLabel")
	typing_controller = TypingControllerScript.new()
	typing_controller.word_label = word_label
	add_child(typing_controller)
	print("Type the word shown above the zombie's head.")

# TODO: Eventually replace this with take_damage()?
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and is_instance_valid(zombie):
		var killed: bool = zombie.take_damage(999.0)
		print("Manual damage applied. Killed: ", killed)

func _on_wall_hit(damage: float) -> void:
	print("Wall hit for ", damage, " damage")
 
func _on_zombie_died(_dead_zombie: Zombie) -> void:
	print("Zombie died")
