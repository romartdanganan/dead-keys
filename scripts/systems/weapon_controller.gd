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
var zombie_manager: ZombieManager
var cooldown_remaining: float = 0.0
var set_jammed := false

# current Bullet Damage upgrade value (#25), applied to each projectile on fire.
# set externally via gameplay_prototype.gd after configure().
var bullet_damage: int = 10

# Spread Shot (#24) cone half-angle between the two outer bullets and centre
const SPREAD_SHOT_ANGLE: float = deg_to_rad(25.0)

# Ricochet (#36): bounces after the initial hit, 3 zombies hit total
const RICOCHET_BOUNCE_COUNT: int = 2

# inject dependencies from the main game scene
func configure(
	new_ammo_system: AmmoSystem,
	new_projectile_container: Node2D
) -> void:
	ammo_system = new_ammo_system
	projectile_container = new_projectile_container


# zombie_manager is created after configure() runs (it doesn't exist until
# the mission actually starts), so it's injected separately once it exists
func set_zombie_manager(new_zombie_manager: ZombieManager) -> void:
	zombie_manager = new_zombie_manager

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
	
	if set_jammed == true:
		return false

	if cooldown_remaining > 0.0:
		return false

	if not ammo_system.consume_ammunition(1):
		attempted_fire_without_ammunition.emit()
		return false

	# Spread Shot (#24), Ricochet (#36) and Piercing Shot (#38): consume the
	# ability charge, not extra ammo
	if AbilityState.equipped_ability_id == "spread_shot" and AbilityState.is_charged:
		_fire_spread_shot(target_position)
		AbilityState.consume_charge()
	elif AbilityState.equipped_ability_id == "ricochet" and AbilityState.is_charged:
		_fire_ricochet_shot(target_position)
		AbilityState.consume_charge()
	elif AbilityState.equipped_ability_id == "piercing_shot" and AbilityState.is_charged:
		_fire_piercing_shot(target_position)
		AbilityState.consume_charge()
	else:
		_spawn_projectile(target_position)

	cooldown_remaining = fire_cooldown
	return true


func _fire_spread_shot(target_position: Vector2) -> void:
	var direction := (target_position - muzzle_point.global_position).normalized()
	for angle: float in [-SPREAD_SHOT_ANGLE, 0.0, SPREAD_SHOT_ANGLE]:
		var spread_target := muzzle_point.global_position + direction.rotated(angle) * 1000.0
		_spawn_projectile(spread_target)


func _fire_ricochet_shot(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.zombie_manager = zombie_manager
	projectile.bounces_remaining = RICOCHET_BOUNCE_COUNT


func _fire_piercing_shot(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.is_piercing = true


func _spawn_projectile(target_position: Vector2) -> Projectile:
	var projectile := projectile_scene.instantiate() as Projectile

	if projectile == null:
		push_error("Projectile scene root must use Projectile.")
		return null

	projectile_container.add_child(projectile)

	projectile.damage = bullet_damage
	projectile.initialise(
		muzzle_point.global_position,
		target_position
	)

	fired.emit(projectile)
	return projectile
