# TO DO

extends Resource
class_name WaveEntry
 
@export var enemy_type: EnemyTypeDef
@export var count: int = 5
@export var spawn_interval: float = 1.5   # seconds between individual spawns within this wave
@export var start_delay: float = 0.0      # seconds after the previous wave clears before this one begins
