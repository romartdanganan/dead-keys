# TO DO

extends CharacterBody2D
class_name Zombie

signal wall_hit(damage: float)
signal died(zombie: Zombie)
signal damaged(zombie: Zombie)

enum State { SPAWN, APPROACH, ATTACK, DEAD}

@export var enemy_type: EnemyTypeDef

var current_state: State = State.SPAWN
var health: float = 0.0
var wall_target: Node2D = null
var current_word: String = "" #TODO: Under the assumption an external system will adjust this

var _time_alive: float = 0.0

@onready var attack_timer: Timer = $AttackTimer
const WALL_CONTACT_DISTANCE: float = 8.0

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	if enemy_type:
		health = enemy_type.health

func setup(type: EnemyTypeDef, wall: Node2D) -> void:
	enemy_type = type
	health = type.health
	wall_target = wall
	_enter_state(State.APPROACH) #TODO: Add animations?

func _physics_process(delta: float) -> void:
	if current_state == State.APPROACH:
		_process_approach(delta)
	_time_alive += delta

func _process_approach(delta: float) -> void:
	if wall_target == null or enemy_type == null:
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
		_enter_state(State.ATTACK)

func _enter_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.ATTACK:
			velocity = Vector2.ZERO
			attack_timer.start()
		State.DEAD:
			attack_timer.stop()
			died.emit(self) # TODO: Despawning for now alter for next milestone
			queue_free()
		_:
			pass


func _on_attack_timer_timeout() -> void:
	if current_state != State.ATTACK:
		return
	wall_hit.emit(enemy_type.wall_damage)

func take_damage(amount: float) -> bool:
	if current_state == State.DEAD:
		return false
	health -= amount
	damaged.emit(self)
	if health <= 0.0:
		_enter_state(State.DEAD)
		return true
	return false
