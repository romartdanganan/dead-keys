class_name Projectile
extends Area2D

# configurable projectile properties visible in the Inspector
@export_range(1.0, 3000.0, 1.0) var speed: float = 900.0
@export_range(0.1, 10.0, 0.1) var maximum_lifetime: float = 3.0
@export_range(1, 100, 1) var damage: int = 1

var direction: Vector2 = Vector2.UP
var lifetime_remaining: float = 0.0


func _ready() -> void:
	lifetime_remaining = maximum_lifetime

	# connect collision signals to handle impacts with Area2D or physics bodies
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# move projectile frame-independently using physics delta
	global_position += direction * speed * delta

	# despawn timer countdown
	lifetime_remaining -= delta

	if lifetime_remaining <= 0.0:
		queue_free()


# called on spawn to set position, aiming direction, and visual rotation
func initialise(
	start_position: Vector2,
	target_position: Vector2
) -> void:
	global_position = start_position

	direction = start_position.direction_to(
		target_position
	).normalized()

	rotation = direction.angle()


func _on_area_entered(area: Area2D) -> void:
	_try_damage_target(area)


func _on_body_entered(body: Node2D) -> void:
	_try_damage_target(body)


# duck typing check: applies damage if the target implements take_damage()
func _try_damage_target(target: Node) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()


# clean up projectile if it flies off-camera before its timer expires
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
