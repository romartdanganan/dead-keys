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

# Freeze Round ability support (#37). set true by WeaponController only for
# a charged Freeze Round shot, normal shots leave it false and behave as before
var is_freeze_round: bool = false
var freeze_duration: float = 0.0
var freeze_radius: float = 0.0

# new ability flags, normal shots leave these off
var is_explosive: bool = false
var explosion_radius: float = 0.0
var explosion_damage: int = 0
var is_homing: bool = false
var is_shockwave: bool = false
var shockwave_radius: float = 0.0
var shockwave_knockback: float = 0.0

# how fast a homing shot turns towards its target
const HOMING_TURN_RATE: float = 10.0


func _ready() -> void:
	lifetime_remaining = maximum_lifetime

	# connect collision signals to handle impacts with Area2D or physics bodies
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	# homing shot bends its direction before moving
	if is_homing:
		_steer_towards_nearest_zombie(delta)

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
		Audio.play("hit_zombie")
		_hit_zombies.append(target)

	if is_freeze_round and target is Zombie:
		_apply_freeze_round(target)

	# explosion and shockwave both centre on the impact point
	if is_explosive and target is Zombie:
		_apply_explosion()
	if is_shockwave and target is Zombie:
		_apply_shockwave()

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


# Freeze Round (#37): freezes the hit zombie and any other active zombies
# within freeze_radius of it, for freeze_duration seconds each
func _apply_freeze_round(hit_zombie: Zombie) -> void:
	Audio.play("freeze")
	hit_zombie.apply_freeze(freeze_duration)
	if zombie_manager == null:
		return
	for zombie: Zombie in zombie_manager.active_zombies:
		if zombie == hit_zombie:
			continue
		# measure from the bullet, a killed pooled zombie is moved off-screen
		if zombie.global_position.distance_to(global_position) <= freeze_radius:
			zombie.apply_freeze(freeze_duration)


# damages every live zombie within explosion_radius of the impact
func _apply_explosion() -> void:
	if zombie_manager == null:
		return
	# duplicate since a kill can change the active list mid-loop
	for zombie: Zombie in zombie_manager.active_zombies.duplicate():
		if zombie.current_state == Zombie.State.DEAD:
			continue
		if zombie.global_position.distance_to(global_position) <= explosion_radius:
			zombie.take_damage(explosion_damage)


# pushes every live zombie in range along the shot direction
func _apply_shockwave() -> void:
	if zombie_manager == null:
		return
	var push := direction * shockwave_knockback
	for zombie: Zombie in zombie_manager.active_zombies.duplicate():
		if zombie.current_state == Zombie.State.DEAD:
			continue
		if zombie.global_position.distance_to(global_position) <= shockwave_radius:
			zombie.apply_knockback(push)


# turns the shot towards the nearest unhit zombie a bit each frame
func _steer_towards_nearest_zombie(delta: float) -> void:
	var target := _find_next_ricochet_target()
	if target == null:
		return
	var desired := global_position.direction_to(target.global_position)
	direction = direction.lerp(desired, clampf(HOMING_TURN_RATE * delta, 0.0, 1.0)).normalized()
	rotation = direction.angle()


# nearest not-yet-hit active zombie, used by Ricochet (#36) to pick the next
# bounce target after a hit
func _find_next_ricochet_target() -> Zombie:
	if zombie_manager == null:
		return null

	var nearest: Zombie = null
	var nearest_distance: float = INF

	for zombie: Zombie in zombie_manager.active_zombies:
		# skip already hit or dead zombies, shared by ricochet and homing
		if zombie in _hit_zombies or zombie.current_state == Zombie.State.DEAD:
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = zombie

	return nearest


# repoints the projectile at a new target without resetting its lifetime,
# so a ricochet chain can't outlive the normal shot lifetime by much
func _redirect_to(target: Zombie) -> void:
	Audio.play("ricochet")
	direction = global_position.direction_to(target.global_position).normalized()
	rotation = direction.angle()


# clean up projectile if it flies off-camera before its timer expires
func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
