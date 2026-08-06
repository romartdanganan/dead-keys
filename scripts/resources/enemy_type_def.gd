# TO DO

extends Resource
class_name EnemyTypeDef

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var health: float = 30.0
@export var speed: float = 60.0  

@export var wall_damage: float = 5.0 # Placeholder number until more enemy types

@export var word_pool_tag: String = "common" # Word tiers
