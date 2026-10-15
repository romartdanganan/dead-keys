# TO DO

extends Resource
class_name EnemyTypeDef

# Special behaviour tag values
const BEHAVIOUR_ZIGZAG: String = "zigzag"
const BEHAVIOUR_MEDIC: String = "medic"
const BEHAVIOUR_COMMANDER: String = "commander"

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var health: float = 30.0
@export var speed: float = 60.0  

@export var wall_damage: float = 5.0 # Placeholder number until more enemy types

@export var word_pool_tag: String = "common" # Word tiers
@export var special_behaviour_tag: String = ""

@export var silhouette_scale: Vector2 = Vector2.ONE
@export var silhouette_modulate: Color = Color.WHITE
@export var word_label_border_color: Color = Color.WHITE
# which art set zombie.tscn plays, "" is the cat and "dog_" is the dog
@export var animation_prefix: String = ""
# the cat art faces left, the dog art faces right
@export var art_faces_right: bool = false

# Only for support behaviours
@export var heal_per_second: float = 10.0
# seconds a zombie must go unhit before a medic starts healing it
@export var heal_delay: float = 2.0
@export var support_radius: float = 180.0
@export var speed_multiplier: float = 1.2

# Only for zigzag behaviour
@export var zigzag_amplitude: float = 0.0
@export var zigzag_frequency: float = 0.0
