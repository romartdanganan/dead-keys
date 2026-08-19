class_name AmmoSystem
extends Node

# emitted whenever current or maximum ammo amounts change
signal ammunition_changed(current_ammo: int, maximum_ammo: int)
# emitted when an action attempts to consume ammo but current_ammo is insufficient
signal ammunition_empty

@export_range(1, 999, 1) var starting_capacity: int = 8

var current_ammo: int = 0
var maximum_ammo: int = 0


func _ready() -> void:
	maximum_ammo = starting_capacity
	_emit_ammunition_changed()


# adds ammo up to maximum capacity and returns the actual amount added
func add_ammunition(amount: int) -> int:
	if amount <= 0:
		return 0

	var previous_ammo := current_ammo

	# clamp to maximum capacity
	current_ammo = mini(
		current_ammo + amount,
		maximum_ammo
	)

	var amount_added := current_ammo - previous_ammo

	_emit_ammunition_changed()
	return amount_added


# tries to spend specified ammo returns false and emits signal if ammo is insufficient
func consume_ammunition(amount: int = 1) -> bool:
	if amount <= 0:
		return true

	if current_ammo < amount:
		ammunition_empty.emit()
		return false

	current_ammo -= amount
	_emit_ammunition_changed()
	return true


# adjusts the maximum ammo capacity (minimum 1) and clamps current ammo to fit
func set_maximum_ammunition(new_maximum: int) -> void:
	maximum_ammo = maxi(new_maximum, 1)
	current_ammo = mini(current_ammo, maximum_ammo)

	_emit_ammunition_changed()


# resets current ammo count back to zero
func reset_ammunition() -> void:
	current_ammo = 0
	_emit_ammunition_changed()


# status helper queries
func is_empty() -> bool:
	return current_ammo <= 0


func is_full() -> bool:
	return current_ammo >= maximum_ammo


# internal helper to notify connected UI elements and systems of ammo updates
func _emit_ammunition_changed() -> void:
	ammunition_changed.emit(
		current_ammo,
		maximum_ammo
	)
