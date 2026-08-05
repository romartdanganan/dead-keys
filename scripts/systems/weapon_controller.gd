class_name WeaponController
extends Node2D

# signals for firing feedback and out-of-ammo UI/audio triggers
signal fired(projectile: Projectile)
signal attempted_fire_without_ammunition

# configurable weapon properties and muzzle marker node
@export var projectile_scene: PackedScene
@export_range(0.0, 5.0, 0.01) var fire_cooldown: float = 0.15

@onready var muzzle_point: Marker2D = $MuzzlePoint

var ammo_system: AmmoSystem
var projectile_container: Node2D
var cooldown_remaining: float = 0.0
var set_jammed := false

# inject dependencies from the main game scene
func configure(
	new_ammo_system: AmmoSystem,
	new_projectile_container: Node2D
) -> void:
	ammo_system = new_ammo_system
	projectile_container = new_projectile_container

# tick down cooldown timer and aim weapon toward mouse cursor
func _process(delta: float) -> void:
	cooldown_remaining = maxf(
		cooldown_remaining - delta,
		0.0
	)

	look_at(get_global_mouse_position())

# validate state, consume ammo, and spawn projectile toward target
func try_fire(target_position: Vector2) -> bool:
	if projectile_scene == null:
		push_warning("WeaponController has no projectile scene.")
		return false

	if ammo_system == null:
		push_warning("WeaponController has no AmmoSystem.")
		return false

	if projectile_container == null:
		push_warning(
			"WeaponController has no projectile container."
		)
		return false

	if cooldown_remaining > 0.0:
		return false

	if not ammo_system.consume_ammunition(1):
		attempted_fire_without_ammunition.emit()
		return false

	var projectile := projectile_scene.instantiate() as Projectile

	if projectile == null:
		push_error(
			"Projectile scene root must use Projectile."
		)
		return false

	if set_jammed == true:
		return false

	projectile_container.add_child(projectile)

	projectile.initialise(
		muzzle_point.global_position,
		target_position
	)

	cooldown_remaining = fire_cooldown
	fired.emit(projectile)

	return true
