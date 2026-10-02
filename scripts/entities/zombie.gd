# TO DO

extends CharacterBody2D
class_name Zombie

signal wall_hit(damage: float)
signal wall_contact()
signal died(zombie: Zombie)
signal damaged(zombie: Zombie)

enum State { SPAWN, APPROACH, SUPPORT, ATTACK, DEAD, FROZEN }

@export var enemy_type: EnemyTypeDef
@export var debug_show_support_radius: bool = false:
	set(value):
		debug_show_support_radius = value
		queue_redraw()

var current_state: State = State.APPROACH
var health: float = 0.0
var wall_target: Node2D = null
var current_word: String = "" #TODO: Under the assumption an external system will adjust this
var is_pooled: bool = false
var _time_alive: float = 0.0
var _support_target: Zombie = null
var _support_log_accumulator: float = 0.0

@onready var attack_timer: Timer = $AttackTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var freeze_timer: Timer = $FreezeTimer
@onready var sprite: Sprite2D = $ZombieSprite2D
@onready var zombie_sprite: Sprite2D = $ZombieSprite2D
# sprite size set in zombie.tscn, per-type silhouette scale multiplies on top
@onready var _base_sprite_scale: Vector2 = $ZombieSprite2D.scale
@onready var word_label: RichTextLabel = $WordLabel

const WALL_CONTACT_DISTANCE: float = 8.0

# Freeze Round ability (#37): tint used so a frozen zombie visually reads as
# frozen, not just internally flagged
const FROZEN_TINT: Color = Color(0.55, 0.8, 1.0)

# state entered before freezing, so a freeze that ends mid-attack resumes
# attacking rather than always dropping back to APPROACH
var _state_before_freeze: State = State.APPROACH

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_to_group("zombies")
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)
	if enemy_type:
		health = enemy_type.health

func setup(type: EnemyTypeDef, wall: Node2D) -> void:
	enemy_type = type
	health = type.health
	wall_target = wall
	current_word = ""
	_time_alive = 0.0
	_support_target = null
	_support_log_accumulator = 0.0
	velocity = Vector2.ZERO
	visible = true
	set_physics_process(true)
	if collision_shape:
		collision_shape.disabled = false
	# pooled zombies reuse this node, a freeze from a previous life must
	# not linger into the new one
	freeze_timer.stop()
	sprite.modulate = Color.WHITE
	_apply_visual_identity()
	queue_redraw()
	_enter_state(State.APPROACH)

func _draw() -> void:
	if not debug_show_support_radius or enemy_type == null:
		return
	if enemy_type.special_behaviour_tag != EnemyTypeDef.BEHAVIOUR_MEDIC:
		return
	draw_circle(Vector2.ZERO, enemy_type.support_radius, Color(0.2, 0.95, 0.75, 0.12))
	draw_arc(Vector2.ZERO, enemy_type.support_radius, 0.0, TAU, 96, Color(0.2, 0.95, 0.75, 0.9), 2.0)

func _apply_visual_identity() -> void:
	if enemy_type == null:
		return
	zombie_sprite.scale = _base_sprite_scale * enemy_type.silhouette_scale
	zombie_sprite.modulate = enemy_type.silhouette_modulate
	var label_style := StyleBoxFlat.new()
	label_style.bg_color = Color(0.02, 0.02, 0.02, 0.75)
	label_style.border_color = enemy_type.word_label_border_color
	label_style.set_border_width_all(3)
	label_style.set_corner_radius_all(4)
	word_label.add_theme_stylebox_override("normal", label_style)

func _physics_process(delta: float) -> void:
	if current_state == State.APPROACH:
		_process_approach(delta)
	elif current_state == State.SUPPORT:
		_process_support(delta)
	_time_alive += delta


func _process_approach(delta: float) -> void:
	if wall_target == null or enemy_type == null:
		return
	if enemy_type.special_behaviour_tag == EnemyTypeDef.BEHAVIOUR_MEDIC:
		_support_target = _find_support_target()
		if _support_target != null:
			_enter_state(State.SUPPORT)
			return
	var base_direction: Vector2 = (wall_target.global_position - global_position).normalized()
	var move_direction: Vector2 = base_direction
	
	if enemy_type.special_behaviour_tag == EnemyTypeDef.BEHAVIOUR_ZIGZAG and enemy_type.zigzag_amplitude > 0.0:
		var perpendicular: Vector2 =  base_direction.orthogonal()
		var oscillation: float = sin(_time_alive * enemy_type.zigzag_frequency * TAU)
		move_direction = (base_direction + perpendicular * oscillation * enemy_type.zigzag_amplitude).normalized()
	
	velocity = move_direction * enemy_type.speed
	move_and_slide()
	if global_position.distance_to(wall_target.global_position) <= WALL_CONTACT_DISTANCE:
		wall_contact.emit()
		_enter_state(State.ATTACK)

func _process_support(delta: float) -> void:
	if enemy_type == null or not is_instance_valid(_support_target):
		_enter_state(State.APPROACH)
		return
	if _support_target.current_state == State.DEAD or _support_target.health >= _support_target.get_max_health():
		_enter_state(State.APPROACH)
		return
	if global_position.distance_to(_support_target.global_position) > enemy_type.support_radius:
		_enter_state(State.APPROACH)
		return
	var healed_amount := _support_target.heal(enemy_type.heal_per_second * delta)
	_support_log_accumulator += healed_amount
	if _support_log_accumulator >= 1.0:
		print(
			"Medic healed ",
			_support_target.enemy_type.display_name,
			" for ",
			_support_log_accumulator,
			" HP (target health: ",
			_support_target.health,
			"/",
			_support_target.get_max_health(),
			")"
		)
		_support_log_accumulator = 0.0

func _find_support_target() -> Zombie:
	if enemy_type == null:
		return null
	var nearest_target: Zombie = null
	var nearest_distance := enemy_type.support_radius
	for node in get_tree().get_nodes_in_group("zombies"):
		var candidate := node as Zombie
		if candidate == null or candidate == self or candidate.current_state == State.DEAD:
			continue
		if candidate.health >= candidate.get_max_health():
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_target = candidate
	return nearest_target

func _enter_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.ATTACK:
			_support_target = null
			velocity = Vector2.ZERO
			attack_timer.start()
		State.SUPPORT:
			attack_timer.stop()
			velocity = Vector2.ZERO
			_support_log_accumulator = 0.0
		State.FROZEN:
			velocity = Vector2.ZERO
			attack_timer.stop()
			sprite.modulate = FROZEN_TINT
		State.DEAD:
			attack_timer.stop()
			freeze_timer.stop()
			velocity = Vector2.ZERO
			if is_pooled:
				_deactivate()
			else:
				queue_free()
			died.emit(self) # TODO: Despawning for now alter for next milestone

func _deactivate() -> void:
	visible = false
	set_physics_process(false)
	if collision_shape:
		collision_shape.disabled = true
	global_position = Vector2(-10000, -10000)


func _on_attack_timer_timeout() -> void:
	if current_state != State.ATTACK:
		return
	wall_hit.emit(enemy_type.wall_damage)

# Freeze Round ability (#37): fully stops movement and attack for
# duration seconds. Re-applying to an already-frozen zombie just refreshes
# the timer rather than stacking a second one.
func apply_freeze(duration: float) -> void:
	if current_state == State.DEAD:
		return
	if current_state != State.FROZEN:
		_state_before_freeze = current_state
		_enter_state(State.FROZEN)
	freeze_timer.start(duration)

func _on_freeze_timer_timeout() -> void:
	if current_state != State.FROZEN:
		return
	sprite.modulate = Color.WHITE
	_enter_state(_state_before_freeze)

func take_damage(amount: float) -> bool:
	if current_state == State.DEAD:
		return false
	health -= amount
	damaged.emit(self)
	if health <= 0.0:
		_enter_state(State.DEAD)
		return true
	return false

func get_max_health() -> float:
	return enemy_type.health if enemy_type != null else 0.0

func heal(amount: float) -> float:
	if current_state == State.DEAD or enemy_type == null:
		return 0.0
	var previous_health := health
	health = minf(health + amount, get_max_health())
	return health - previous_health
