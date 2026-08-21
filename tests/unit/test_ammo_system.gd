extends GutTest

# AmmoSystem has no external @onready dependencies, so it can be tested
# directly with a plain instance.

var ammo_system: AmmoSystem


func before_each() -> void:
	ammo_system = AmmoSystem.new()
	ammo_system.starting_capacity = 8
	add_child_autofree(ammo_system)


# fresh instance should start empty, maxed out at starting_capacity
func test_starts_at_zero_ammo_with_starting_capacity_as_max() -> void:
	assert_eq(ammo_system.current_ammo, 0)
	assert_eq(ammo_system.maximum_ammo, 8)


# add_ammunition() should return how much was actually added
func test_add_ammunition_increases_current_ammo() -> void:
	var added := ammo_system.add_ammunition(3)
	assert_eq(added, 3)
	assert_eq(ammo_system.current_ammo, 3)


# adding more than the remaining capacity should cap at maximum_ammo,
# and the returned amount should reflect only what actually fit
func test_add_ammunition_clamps_to_maximum() -> void:
	var added := ammo_system.add_ammunition(20)
	assert_eq(added, 8)
	assert_eq(ammo_system.current_ammo, 8)


# zero or negative amounts should be a no-op, not an error
func test_add_ammunition_ignores_non_positive_amounts() -> void:
	assert_eq(ammo_system.add_ammunition(0), 0)
	assert_eq(ammo_system.add_ammunition(-5), 0)
	assert_eq(ammo_system.current_ammo, 0)


# normal case: enough ammo on hand covers the cost
func test_consume_ammunition_succeeds_when_enough_ammo() -> void:
	ammo_system.add_ammunition(5)
	var consumed := ammo_system.consume_ammunition(2)
	assert_true(consumed)
	assert_eq(ammo_system.current_ammo, 3)


# consuming with zero ammo should fail and fire ammunition_empty
func test_consume_ammunition_fails_and_emits_signal_when_insufficient() -> void:
	watch_signals(ammo_system)
	var consumed := ammo_system.consume_ammunition(1)
	assert_false(consumed)
	assert_signal_emitted(ammo_system, "ammunition_empty")
	assert_eq(ammo_system.current_ammo, 0)


# a failed consume should never push current_ammo negative
func test_consume_ammunition_cannot_go_below_zero() -> void:
	ammo_system.add_ammunition(2)
	ammo_system.consume_ammunition(2)
	var consumed := ammo_system.consume_ammunition(1)
	assert_false(consumed)
	assert_eq(ammo_system.current_ammo, 0)


# lowering the cap (e.g. a downgrade or reset) should also pull
# current_ammo down to fit, not leave it over the new maximum
func test_set_maximum_ammunition_clamps_current_ammo_down() -> void:
	ammo_system.add_ammunition(8)
	ammo_system.set_maximum_ammunition(4)
	assert_eq(ammo_system.maximum_ammo, 4)
	assert_eq(ammo_system.current_ammo, 4)


# maximum_ammo should never be settable to zero or below
func test_set_maximum_ammunition_has_a_floor_of_one() -> void:
	ammo_system.set_maximum_ammunition(0)
	assert_eq(ammo_system.maximum_ammo, 1)


# reset_ammunition() only zeroes current ammo, capacity is untouched
func test_reset_ammunition_zeroes_current_ammo_only() -> void:
	ammo_system.add_ammunition(5)
	ammo_system.reset_ammunition()
	assert_eq(ammo_system.current_ammo, 0)
	assert_eq(ammo_system.maximum_ammo, 8)


# is_empty()/is_full() should track current_ammo relative to maximum_ammo
func test_is_empty_and_is_full_helpers() -> void:
	assert_true(ammo_system.is_empty())
	assert_false(ammo_system.is_full())

	ammo_system.add_ammunition(8)
	assert_false(ammo_system.is_empty())
	assert_true(ammo_system.is_full())
