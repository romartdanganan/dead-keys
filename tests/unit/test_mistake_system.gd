extends GutTest

# MistakeSystem resolves its dependencies via relative "../..." paths, so
# this harness rebuilds the exact sibling structure it expects instead of
# mocking it. No refactor of MistakeSystem itself for testability.

var mistake_system: MistakeSystem
var ammo_system: AmmoSystem
var typing_controller: TypingController
var weapon_controller: WeaponController


# builds a minimal node tree matching MistakeSystem's expected sibling
# layout (AmmoSystem, TypingController, World/WeaponController, and the
# HUD path to its mistakes label), then adds it so _ready() actually runs
func before_each() -> void:
	var root := Node.new()

	ammo_system = AmmoSystem.new()
	ammo_system.name = "AmmoSystem"
	ammo_system.starting_capacity = 8
	root.add_child(ammo_system)

	typing_controller = TypingController.new()
	typing_controller.name = "TypingController"
	root.add_child(typing_controller)

	var world := Node.new()
	world.name = "World"
	root.add_child(world)

	weapon_controller = WeaponController.new()
	weapon_controller.name = "WeaponController"
	var muzzle_point := Marker2D.new()
	muzzle_point.name = "MuzzlePoint"
	weapon_controller.add_child(muzzle_point)
	world.add_child(weapon_controller)

	var hud := Node.new()
	hud.name = "HUD"
	root.add_child(hud)
	var hud_root := Node.new()
	hud_root.name = "HUDRoot"
	hud.add_child(hud_root)
	var typing_panel := Node.new()
	typing_panel.name = "TypingPanel"
	hud_root.add_child(typing_panel)
	var mistake_panel := Node.new()
	mistake_panel.name = "MistakePanel"
	typing_panel.add_child(mistake_panel)
	var mistake_margin := Node.new()
	mistake_margin.name = "MistakeMargin"
	mistake_panel.add_child(mistake_margin)
	var mistakes_label := Label.new()
	mistakes_label.name = "MistakesLabel"
	mistake_margin.add_child(mistakes_label)

	mistake_system = MistakeSystem.new()
	mistake_system.name = "MistakeSystem"
	root.add_child(mistake_system)

	add_child_autofree(root)

	# force known baseline values regardless of whatever UpgradeState
	# currently holds globally (purchased upgrades persist across the
	# whole test run/editor session), individual tests can override further
	mistake_system.mistakes_before_ammo_loss = 1
	mistake_system.jam_cooldown = 2.0
	mistake_system.mistake_count = 0
	mistake_system.mistakes_since_ammo_loss = 0


# three typing_mistake signals in a row should flip the weapon jammed,
# but the first two alone should not
func test_three_consecutive_mistakes_trigger_a_jam() -> void:
	ammo_system.add_ammunition(8)

	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()
	assert_false(weapon_controller.set_jammed)

	typing_controller.typing_mistake.emit()
	assert_true(weapon_controller.set_jammed)


# a correct_stroke signal between mistakes should break the streak, so
# two more mistakes afterward shouldn't be enough to reach the jam threshold
func test_correct_stroke_resets_the_consecutive_mistake_count() -> void:
	ammo_system.add_ammunition(8)

	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()
	typing_controller.correct_stroke.emit()
	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()

	assert_false(weapon_controller.set_jammed)


# regression test for the #20 edge case: mistakes made while already
# jammed must not silently queue up a second jam
func test_mistake_during_an_active_jam_does_not_queue_another_jam() -> void:
	ammo_system.add_ammunition(8)

	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()
	assert_true(weapon_controller.set_jammed)

	# further mistakes while jammed should not build toward a second jam
	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()
	typing_controller.typing_mistake.emit()

	assert_eq(mistake_system.mistake_count, 0)


# at the base Mistake Leniency level (1), every single mistake should
# cost exactly one ammo, matching the original pre-upgrade design
func test_every_mistake_consumes_ammo_at_base_leniency() -> void:
	ammo_system.add_ammunition(8)

	typing_controller.typing_mistake.emit()

	assert_eq(ammo_system.current_ammo, 7)


# with the Mistake Leniency upgrade at level 2, ammo should only be lost
# on the second consecutive mistake, not the first
func test_mistake_leniency_delays_ammo_loss_until_the_threshold() -> void:
	ammo_system.add_ammunition(8)
	mistake_system.mistakes_before_ammo_loss = 2

	typing_controller.typing_mistake.emit()
	assert_eq(ammo_system.current_ammo, 8)

	typing_controller.typing_mistake.emit()
	assert_eq(ammo_system.current_ammo, 7)


# a mistake with zero ammo on hand should just fail quietly, not error
# or wrap around to a negative value
func test_mistake_with_zero_ammo_does_not_go_negative() -> void:
	typing_controller.typing_mistake.emit()
	assert_eq(ammo_system.current_ammo, 0)
