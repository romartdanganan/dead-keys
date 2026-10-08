extends GutTest

# normal shots never use the charge, the ability only fires on its own input

const ProjectileScene := preload("res://scenes/entities/projectile.tscn")

var weapon: WeaponController
var ammo: AmmoSystem
var container: Node2D
var _saved_charged: bool
var _saved_ability: String


func before_each() -> void:
	_saved_charged = AbilityState.is_charged
	_saved_ability = AbilityState.equipped_ability_id
	AbilityState.is_charged = false
	AbilityState.equipped_ability_id = "spread_shot"

	ammo = AmmoSystem.new()
	ammo.starting_capacity = 8
	add_child_autofree(ammo)
	ammo.add_ammunition(8)
	container = Node2D.new()
	add_child_autofree(container)

	weapon = WeaponController.new()
	weapon.projectile_scene = ProjectileScene
	var muzzle := Marker2D.new()
	muzzle.name = "MuzzlePoint"
	weapon.add_child(muzzle)
	add_child_autofree(weapon)
	weapon.configure(ammo, container)
	weapon.fire_cooldown = 0.0


func after_each() -> void:
	AbilityState.is_charged = _saved_charged
	AbilityState.equipped_ability_id = _saved_ability


func test_normal_shot_keeps_the_charge() -> void:
	AbilityState.is_charged = true
	assert_true(weapon.try_fire(Vector2(500, 0)))
	assert_true(AbilityState.is_charged)
	assert_eq(container.get_child_count(), 1)


func test_ability_input_fires_the_ability_and_uses_the_charge() -> void:
	AbilityState.is_charged = true
	assert_true(weapon.try_fire_ability(Vector2(500, 0)))
	assert_false(AbilityState.is_charged)
	# spread shot fires three bullets for one ammo
	assert_eq(container.get_child_count(), 3)
	assert_eq(ammo.current_ammo, 7)


func test_ability_input_does_nothing_without_a_charge() -> void:
	assert_false(weapon.try_fire_ability(Vector2(500, 0)))
	assert_eq(ammo.current_ammo, 8)
	assert_eq(container.get_child_count(), 0)


func test_ability_needs_ammo_and_keeps_the_charge_when_empty() -> void:
	ammo.reset_ammunition()
	AbilityState.is_charged = true
	assert_false(weapon.try_fire_ability(Vector2(500, 0)))
	assert_true(AbilityState.is_charged)


func test_jammed_weapon_cannot_fire_the_ability() -> void:
	AbilityState.is_charged = true
	weapon.set_jammed = true
	assert_false(weapon.try_fire_ability(Vector2(500, 0)))
	assert_true(AbilityState.is_charged)
