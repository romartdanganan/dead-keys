# TO DO

extends CharacterBody2D
class_name Zombie

signal wall_hit(damage: float)
signal wall_contact()
signal died(zombie: Zombie)
# emitted once the death animation ends, right before the zombie is hidden or freed
signal death_finished(zombie: Zombie)
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
var wall_contact_radius: float = WALL_CONTACT_DISTANCE
var current_word: String = "" #TODO: Under the assumption an external system will adjust this
var is_pooled: bool = false
var _time_alive: float = 0.0
var _support_target: Zombie = null
var _support_log_accumulator: float = 0.0
var allowed_buckets: Array[int] = [] #words handling



@onready var attack_timer: Timer = $AttackTimer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var freeze_timer: Timer = $FreezeTimer
@onready var sprite: Sprite2D = $ZombieSprite2D
@onready var zombie_sprite: Sprite2D = $ZombieSprite2D
# sprite size set in zombie.tscn, per-type silhouette scale multiplies on top
@onready var _base_sprite_scale: Vector2 = $ZombieSprite2D.scale
@onready var word_label: RichTextLabel = $WordLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const WALL_CONTACT_DISTANCE: float = 8.0

# Freeze Round ability (#37): tint used so a frozen zombie visually reads as
# frozen, not just internally flagged
const FROZEN_TINT: Color = Color(0.55, 0.8, 1.0)

# state entered before freezing, so a freeze that ends mid-attack resumes
# attacking rather than always dropping back to APPROACH
var _state_before_freeze: State = State.APPROACH

# smooth knockback, velocity eases to zero over KNOCKBACK_DURATION
const KNOCKBACK_DURATION: float = 0.3
var _knockback_remaining: float = 0.0
var _knockback_start_velocity: Vector2 = Vector2.ZERO

# medics wait until a zombie hasn't been hit for heal_delay seconds before healing it
var seconds_since_damaged: float = INF

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_to_group("zombies")
	freeze_timer.timeout.connect(_on_freeze_timer_timeout)
	# hides or frees the zombie once its death animation ends
	animation_player.animation_finished.connect(_on_animation_finished)
	if enemy_type:
		health = enemy_type.health

func setup(type: EnemyTypeDef, wall: Node2D, contact_radius: float = WALL_CONTACT_DISTANCE) -> void:
	enemy_type = type
	health = type.health
	wall_target = wall
	wall_contact_radius = maxf(contact_radius, WALL_CONTACT_DISTANCE)
	current_word = ""
	_time_alive = 0.0
	_support_target = null
	_support_log_accumulator = 0.0
	seconds_since_damaged = INF
	# pooled zombies must not keep sliding from a previous life
	_knockback_remaining = 0.0
	velocity = Vector2.ZERO
	visible = true
	set_physics_process(true)
	# deferred since a spawn can happen inside a bullet hit, where physics refuses changes
	if collision_shape:
		collision_shape.set_deferred("disabled", false)
	# pooled zombies reuse this node, a freeze from a previous life must
	# not linger into the new one
	freeze_timer.stop()
	sprite.modulate = Color.WHITE
	# a reused zombie may have died mid animation, so bring back its label and walk
	word_label.visible = true
	_play_art_animation("walk")
	_update_facing()
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

# flips the art so it always faces the wall, cat art faces left and dog art faces right
func _update_facing() -> void:
	if wall_target == null:
		return
	var left_of_wall := global_position.x < wall_target.global_position.x
	var faces_right := enemy_type != null and enemy_type.art_faces_right
	zombie_sprite.flip_h = left_of_wall != faces_right


# plays this type's art set, e.g. "walk" becomes "dog_walk" for the runner
func _play_art_animation(anim_name: String) -> void:
	var prefix := enemy_type.animation_prefix if enemy_type != null else ""
	# frame 0 exists on every sheet, so swapping sheets never lands on a missing frame
	zombie_sprite.frame = 0
	animation_player.play(prefix + anim_name)
	# applies the sheet straight away so a reused zombie never shows the old art for a frame
	animation_player.advance(0)

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
	seconds_since_damaged += delta
	# flips the sprite to face the wall from whichever side the zombie is on
	_update_facing()
	# a knockback slide overrides normal movement until it finishes
	if _knockback_remaining > 0.0:
		_process_knockback(delta)
		_time_alive += delta
		return
	if current_state == State.APPROACH:
		_process_approach(delta)
	elif current_state == State.ATTACK:
		_process_attack()
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
	if enemy_type.special_behaviour_tag == EnemyTypeDef.BEHAVIOUR_COMMANDER:
		if _has_nearby_support_target():
			_enter_state(State.SUPPORT)
			return
	var base_direction: Vector2 = (wall_target.global_position - global_position).normalized()
	if global_position.distance_to(wall_target.global_position) <= wall_contact_radius:
		_reach_wall()
		return
	var move_direction: Vector2 = base_direction
	
	if enemy_type.special_behaviour_tag == EnemyTypeDef.BEHAVIOUR_ZIGZAG and enemy_type.zigzag_amplitude > 0.0:
		var perpendicular: Vector2 =  base_direction.orthogonal()
		var oscillation: float = sin(_time_alive * enemy_type.zigzag_frequency * TAU)
		move_direction = (base_direction + perpendicular * oscillation * enemy_type.zigzag_amplitude).normalized()
	
	velocity = move_direction * get_movement_speed()
	move_and_slide()
	if global_position.distance_to(wall_target.global_position) <= wall_contact_radius:
		_reach_wall()

func _process_attack() -> void:
	if wall_target == null:
		return
	var distance_to_wall := global_position.distance_to(wall_target.global_position)
	if distance_to_wall > wall_contact_radius + 1.0:
		_enter_state(State.APPROACH)
	elif distance_to_wall < wall_contact_radius:
		_clamp_to_wall_edge()

func _reach_wall() -> void:
	_clamp_to_wall_edge()
	wall_contact.emit()
	_enter_state(State.ATTACK)

func _clamp_to_wall_edge() -> void:
	if wall_target == null:
		return
	var offset := global_position - wall_target.global_position
	if offset.is_zero_approx():
		offset = Vector2.RIGHT
	global_position = wall_target.global_position + offset.normalized() * wall_contact_radius

func _process_support(delta: float) -> void:
	if enemy_type != null and enemy_type.special_behaviour_tag == EnemyTypeDef.BEHAVIOUR_COMMANDER:
		if _has_nearby_support_target():
			return
		_enter_state(State.APPROACH)
		return
	if enemy_type == null or not is_instance_valid(_support_target):
		_enter_state(State.APPROACH)
		return
	if _support_target.current_state == State.DEAD or _support_target.health >= _support_target.get_max_health():
		_enter_state(State.APPROACH)
		return
	if global_position.distance_to(_support_target.global_position) > enemy_type.support_radius:
		_enter_state(State.APPROACH)
		return
	# a quick burst of shots should finish a zombie before the medic can undo it,
	# so freshly hit zombies are only healed once the player stops hitting them
	if _support_target.seconds_since_damaged < enemy_type.heal_delay:
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

func _has_nearby_support_target() -> bool:
	if enemy_type == null:
		return false
	for node in get_tree().get_nodes_in_group("zombies"):
		var candidate := node as Zombie
		if candidate == null or candidate == self or candidate.current_state == State.DEAD:
			continue
		if global_position.distance_to(candidate.global_position) <= enemy_type.support_radius:
			return true
	return false

func get_movement_speed() -> float:
	if enemy_type == null:
		return 0.0
	var movement_speed := enemy_type.speed
	for node in get_tree().get_nodes_in_group("zombies"):
		var commander := node as Zombie
		if commander == null or commander == self or commander.current_state == State.DEAD:
			continue
		if commander.enemy_type == null or commander.enemy_type.special_behaviour_tag != EnemyTypeDef.BEHAVIOUR_COMMANDER:
			continue
		if global_position.distance_to(commander.global_position) <= commander.enemy_type.support_radius:
			movement_speed *= commander.enemy_type.speed_multiplier
	# zombie speed accessibility setting, 1.0 unless the player slows zombies down
	return movement_speed * SettingsState.get_zombie_speed_multiplier()

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
			_start_death_animation()
			Audio.play("kill_zombie")
			died.emit(self) # TODO: Despawning for now alter for next milestone

# the corpse stays in place and can't be hit or moved while the death animation plays
func _start_death_animation() -> void:
	set_physics_process(false)
	_knockback_remaining = 0.0
	# deferred so the hitbox really turns off when a bullet kills it, letting shots pass the corpse
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	word_label.visible = false
	_play_art_animation("death")


# tells the pool and the poof effect the corpse is done, then hides or frees it
func _on_animation_finished(anim_name: StringName) -> void:
	if not String(anim_name).ends_with("death") or current_state != State.DEAD:
		return
	death_finished.emit(self)
	if is_pooled:
		_deactivate()
	else:
		queue_free()

func _deactivate() -> void:
	visible = false
	set_physics_process(false)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
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

# moves the zombie by offset, a pushed attacker goes back to approaching
func apply_knockback(offset: Vector2) -> void:
	if current_state == State.DEAD:
		return
	# start fast and ease to a stop, total slide distance equals offset
	_knockback_start_velocity = offset * 2.0 / KNOCKBACK_DURATION
	_knockback_remaining = KNOCKBACK_DURATION
	if current_state == State.ATTACK:
		_enter_state(State.APPROACH)
	# a frozen attacker should approach again once the freeze ends
	elif current_state == State.FROZEN and _state_before_freeze == State.ATTACK:
		_state_before_freeze = State.APPROACH

func _process_knockback(delta: float) -> void:
	var step := minf(delta, _knockback_remaining)
	# midpoint speed of this step keeps the total slide distance exact
	velocity = _knockback_start_velocity * ((_knockback_remaining - step * 0.5) / KNOCKBACK_DURATION)
	global_position += velocity * step
	_knockback_remaining -= step
	if _knockback_remaining <= 0.0:
		velocity = Vector2.ZERO

func take_damage(amount: float) -> bool:
	if current_state == State.DEAD:
		return false
	health -= amount
	seconds_since_damaged = 0.0
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
