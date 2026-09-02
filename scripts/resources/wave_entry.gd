# TO DO

extends Resource
class_name WaveEntry
 
@export var enemy_type: EnemyTypeDef
@export var count: int = 5
@export var spawn_interval: float = 1.5   # seconds between individual spawns within this wave
@export var start_delay: float = 0.0      # seconds after the previous wave clears before this one begins

# groups multiple WaveEntry rows under one on-screen "WAVE N" announcement,
# e.g. a Walker batch immediately followed by a Runner batch at the same
# number so the player sees one mixed wave instead of two separate ones.
# -1 (default) means auto: this entry gets its own announcement number,
# unchanged from the original single-type-per-wave behaviour
@export var display_wave_number: int = -1
