class_name ProjectileTestTarget
extends Area2D

# configurable target hit points visible in the inspector
@export_range(1, 100, 1) var maximum_health: int = 3

@onready var health_label: Label = $HealthLabel

var current_health: int = 0


func _ready() -> void:
	current_health = maximum_health
	_update_label()


# called by projectile on impact to apply damage and destroy target at 0 hp
func take_damage(amount: int) -> void:
	if amount <= 0:
		return

	current_health = maxi(
		current_health - amount,
		0
	)

	_update_label()

	print(
		"Test target health: ",
		current_health,
		"/",
		maximum_health
	)

	if current_health <= 0:
		queue_free()


# update health label text over the target
func _update_label() -> void:
	health_label.text = "HP: %d" % current_health
