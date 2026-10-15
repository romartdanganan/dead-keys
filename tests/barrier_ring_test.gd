extends Node2D

const ZOMBIE_SCENE := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE := preload("res://resources/enemies/walker.tres")
const RING_RADIUS := 105.0
const TEST_CENTRE := Vector2(640.0, 360.0)
const ZOMBIE_COUNT := 8

@onready var results_label: Label = $Results
@onready var status_label: Label = $Status

var zombies: Array[Zombie] = []
var contact_count := 0
var wall_hit_count := 0
var test_finished := false

func _ready() -> void:
	_spawn_test_zombies()
	_run_tests()

func _spawn_test_zombies() -> void:
	for index in ZOMBIE_COUNT:
		var zombie := ZOMBIE_SCENE.instantiate() as Zombie
		add_child(zombie)
		var angle := TAU * float(index) / float(ZOMBIE_COUNT)
		zombie.global_position = TEST_CENTRE + Vector2.RIGHT.rotated(angle) * 280.0
		zombie.setup(WALKER_TYPE, $WallTarget, RING_RADIUS)
		zombie.wall_contact.connect(_on_wall_contact)
		zombie.wall_hit.connect(_on_wall_hit)
		zombies.append(zombie)

func _run_tests() -> void:
	status_label.text = "Running ring tests..."
	await get_tree().create_timer(8.0).timeout

	var edge_results: Array[bool] = []
	for zombie in zombies:
		edge_results.append(
			is_instance_valid(zombie)
			and zombie.current_state == Zombie.State.ATTACK
			and absf(zombie.global_position.distance_to(TEST_CENTRE) - RING_RADIUS) <= 2.0
		)
	var edge_passed := edge_results.all(func(value: bool) -> bool: return value)
	var spread_passed := _has_spread_attack_positions()
	var contact_passed := contact_count == ZOMBIE_COUNT
	var damage_passed := wall_hit_count > 0

	# Simulate Shockwave knockback by moving an attacking zombie away from the
	# ring. Its normal approach logic must return it to the ring.
	var knocked_zombie := zombies[0]
	knocked_zombie.global_position = TEST_CENTRE + Vector2.RIGHT * 200.0
	await get_tree().create_timer(4.0).timeout
	var knockback_passed := (
		knocked_zombie.current_state == Zombie.State.ATTACK
		and absf(knocked_zombie.global_position.distance_to(TEST_CENTRE) - RING_RADIUS) <= 2.0
	)

	# Freeze an attacking zombie and verify it resumes attack at the ring.
	var frozen_zombie := zombies[1]
	frozen_zombie.apply_freeze(1.0)
	var frozen_state_passed := frozen_zombie.current_state == Zombie.State.FROZEN
	await get_tree().create_timer(1.3).timeout
	var freeze_resume_passed := frozen_zombie.current_state == Zombie.State.ATTACK

	_show_result("Ring edge contact", edge_passed)
	_show_result("360-degree spread", spread_passed)
	_show_result("wall_contact signal", contact_passed)
	_show_result("wall_hit signal", damage_passed)
	_show_result("Knockback returns to ring", knockback_passed)
	_show_result("Freeze pauses zombie", frozen_state_passed)
	_show_result("Freeze resumes attack", freeze_resume_passed)
	status_label.text = "Tests complete. See results below."
	test_finished = true

func _has_spread_attack_positions() -> bool:
	var angles: Array[float] = []
	for zombie in zombies:
		if not is_instance_valid(zombie):
			return false
		angles.append((TEST_CENTRE.direction_to(zombie.global_position)).angle())
	angles.sort()
	for index in angles.size():
		var next_index := (index + 1) % angles.size()
		var gap := angles[next_index] - angles[index]
		if next_index == 0:
			gap += TAU
		if gap < 0.15:
			return false
	return true

func _show_result(test_name: String, passed: bool) -> void:
	results_label.text += "%s: %s\n" % [test_name, "PASS" if passed else "FAIL"]

func _on_wall_contact() -> void:
	contact_count += 1

func _on_wall_hit(_damage: float) -> void:
	wall_hit_count += 1
