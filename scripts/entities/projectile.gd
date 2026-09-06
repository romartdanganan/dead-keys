class_name Projectile
extends Area2D

# configurable projectile properties visible in the Inspector
@export_range(1.0, 3000.0, 1.0) var speed: float = 900.0
@export_range(0.1, 10.0, 0.1) var maximum_lifetime: float = 3.0
@export_range(1, 100, 1) var damage: int = 1

var direction: Vector2 = Vector2.UP
var lifetime_remaining: float = 0.0

# Ricochet ability support (#36). zombie_manager is only set by
# WeaponController when this shot is a charged Ricochet shot, normal shots
# leave it null and bounces_remaining at 0, so they behave exactly as before
var zombie_manager: ZombieManager = null
var bounces_remaining: int = 0
var _hit_zombies: Array[Zombie] = []

# Piercing Shot ability support (#38). set true by WeaponController only for
# a charged Piercing Shot, normal shots leave it false and behave as before
var is_piercing: bool = false


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
	if not target.has_method("take_damage"):
		return

	# prevents a fat hitbox from re-triggering area_entered on the same
	# zombie more than once, matters most for Piercing Shot (#38)
	if target is Zombie and target in _hit_zombies:
		return

	target.take_damage(damage)

	if target is Zombie:
		_hit_zombies.append(target)

	if bounces_remaining > 0:
		var next_target := _find_next_ricochet_target()
		if next_target != null:
			bounces_remaining -= 1
			_redirect_to(next_target)
			return

	# Piercing Shot (#38) keeps travelling after a hit, only the screen-exit
	# notifier or lifetime timer frees it, not this collision handler
	if is_piercing:
		return

	queue_free()


# nearest not-yet-hit active zombie, used by Ricochet (#36) to pick the next
# bounce target after a hit
func _find_next_ricochet_target() -> Zombie:
	if zombie_manager == null:
		return null

	var nearest: Zombie = null
	var nearest_distance: float = INF

	for zombie: Zombie in zombie_manager.active_zombies:
		if zombie in _hit_zombies:
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = zombie

	return nearest


# repoints the projectile at a new target without resetting its lifetime,
# so a ricochet chain can't outlive the normal shot lifetime by much
func _redirect_to(target: Zombie) -> void:
	direction = global_position.direction_to(target.global_position).normalized()
	rotation = direction.angle()


# clean up projectile if it flies off-camera before its timer expires
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
