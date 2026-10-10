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

# false lets the next entry start once this one has finished spawning,
# so different enemy types can be on screen together
@export var wait_for_clear: bool = true

# true keeps spawns to the left and right sides (corners included), which gives
# slow tough enemies like the tank the widest part of the screen to cross
@export var side_spawn_only: bool = false

# which word buckets (GDD §2.2.1) this wave's zombies can get
# 1 = 3-4 letters, 2 = 5-7, 3 = 8-10, 4 = 11+
# empty = any bucket the mission allows
@export var allowed_buckets: Array[int] = []
