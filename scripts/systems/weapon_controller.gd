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

# Freeze Round (#37): duration and radius are not specified in the GDD,
# first-pass judgment call, flagged in the MR for review
const FREEZE_ROUND_DURATION: float = 2.5
const FREEZE_ROUND_RADIUS: float = 140.0

# new ability tuning, first-pass numbers for playtesting
# bigger radius since zombies spread out from 360 spawning
const EXPLOSIVE_ROUND_RADIUS: float = 200.0
const EXPLOSIVE_ROUND_SPLASH_MULTIPLIER: int = 2
const HEAVY_ROUND_DAMAGE_MULTIPLIER: int = 5
const SHOCKWAVE_ROUND_RADIUS: float = 120.0
const SHOCKWAVE_ROUND_KNOCKBACK: float = 150.0

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

# normal shot, never uses the ability charge
func try_fire(target_position: Vector2) -> bool:
	if not _take_shot():
		return false
	_spawn_projectile(target_position)
	Audio.play("shoot")
	return true


# the charged ability now fires only on its own input so the player picks the moment,
# it costs one bullet like a normal shot and uses up the charge
func try_fire_ability(target_position: Vector2) -> bool:
	if not AbilityState.is_charged:
		return false
	if not _take_shot():
		return false

	match AbilityState.equipped_ability_id:
		"spread_shot":
			Audio.play("spread_shot")
			_fire_spread_shot(target_position)
		"ricochet":
			Audio.play("shoot")
			_fire_ricochet_shot(target_position)
		"piercing_shot":
			Audio.play("piercing_shot")
			_fire_piercing_shot(target_position)
		"freeze_round":
			Audio.play("freeze_round")
			_fire_freeze_round(target_position)
		"explosive_round":
			Audio.play("explosive_round")
			_fire_explosive_round(target_position)
		"heavy_round":
			Audio.play("heavy_round")
			_fire_heavy_round(target_position)
		"homing_shot":
			Audio.play("homing_shot")
			_fire_homing_shot(target_position)
		"shockwave_round":
			Audio.play("shockwave_round")
			_fire_shockwave_round(target_position)
		_:
			_spawn_projectile(target_position)

	AbilityState.consume_charge()
	return true


# shared checks for both shot types: set up, not jammed, off cooldown, has ammo
func _take_shot() -> bool:
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
		Audio.play("jammed")
		return false

	if cooldown_remaining > 0.0:
		return false

	if not ammo_system.consume_ammunition(1):
		Audio.play("no_ammo")
		attempted_fire_without_ammunition.emit()
		return false

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


func _fire_freeze_round(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.zombie_manager = zombie_manager
	projectile.is_freeze_round = true
	projectile.freeze_duration = FREEZE_ROUND_DURATION
	projectile.freeze_radius = FREEZE_ROUND_RADIUS


func _fire_explosive_round(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.zombie_manager = zombie_manager
	projectile.is_explosive = true
	projectile.explosion_radius = EXPLOSIVE_ROUND_RADIUS
	projectile.explosion_damage = bullet_damage * EXPLOSIVE_ROUND_SPLASH_MULTIPLIER


func _fire_heavy_round(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	# overrides the normal damage _spawn_projectile already set
	projectile.damage = bullet_damage * HEAVY_ROUND_DAMAGE_MULTIPLIER


func _fire_homing_shot(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.zombie_manager = zombie_manager
	projectile.is_homing = true


func _fire_shockwave_round(target_position: Vector2) -> void:
	var projectile := _spawn_projectile(target_position)
	if projectile == null:
		return
	projectile.zombie_manager = zombie_manager
	projectile.is_shockwave = true
	projectile.shockwave_radius = SHOCKWAVE_ROUND_RADIUS
	projectile.shockwave_knockback = SHOCKWAVE_ROUND_KNOCKBACK


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
