extends GutTest

# hit flash, ammo popups and the out of ammo prompt, driven by the signals the mission uses

const CombatFeedbackScript := preload("res://scripts/missions/combat_feedback.gd")
const ZombieScene := preload("res://scenes/entities/zombie.tscn")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

var feedback: Node2D
var typing: TypingController
var manager: ZombieManager
var weapon: WeaponController
var ammo: AmmoSystem
var ammo_panel: PanelContainer
var wall: Node2D
var _original_reduce: bool


func before_each() -> void:
	_original_reduce = SettingsState.reduce_flashing
	SettingsState.reduce_flashing = false
	typing = TypingController.new()
	typing.word_list_path = ""
	add_child_autofree(typing)
	manager = ZombieManager.new()
	add_child_autofree(manager)
	weapon = WeaponController.new()
	ammo = AmmoSystem.new()
	add_child_autofree(ammo)
	ammo_panel = PanelContainer.new()
	add_child_autofree(ammo_panel)
	wall = Node2D.new()
	wall.global_position = Vector2(5000, 0)
	add_child_autofree(wall)
	feedback = CombatFeedbackScript.new()
	add_child_autofree(feedback)
	feedback.setup(typing, manager, weapon, ammo, ammo_panel)


func after_each() -> void:
	weapon.free()
	SettingsState.reduce_flashing = _original_reduce


func _popups() -> Array[Label]:
	var labels: Array[Label] = []
	for child in feedback.get_children():
		if child is Label:
			labels.append(child)
	return labels


func _zombie_with_word(word: String) -> Zombie:
	var zombie: Zombie = ZombieScene.instantiate()
	zombie.is_pooled = true
	add_child_autofree(zombie)
	zombie.setup(WALKER_TYPE, wall)
	typing.register_target(zombie, zombie.word_label)
	typing.active_targets[typing.active_targets.size() - 1]["word"] = word
	return zombie


func test_popup_text_shows_ammo_gained_or_full() -> void:
	assert_eq(CombatFeedbackScript.ammo_popup_text(2), "+2 AMMO")
	assert_eq(CombatFeedbackScript.ammo_popup_text(0), "AMMO FULL")


func test_finished_word_pops_up_the_ammo_actually_added() -> void:
	_zombie_with_word("code")
	# same order as the mission: ammo is added first, then the popup runs
	ammo.add_ammunition(1)
	typing.word_completed.emit("code", 1)

	assert_eq(_popups().size(), 1)
	assert_eq(_popups()[0].text, "+1 AMMO")


func test_finished_word_with_full_ammo_says_full() -> void:
	_zombie_with_word("code")
	ammo.add_ammunition(ammo.maximum_ammo)
	ammo.add_ammunition(1)
	typing.word_completed.emit("code", 1)

	assert_eq(_popups()[0].text, "AMMO FULL")


func test_damaged_zombie_flashes_then_returns_to_normal() -> void:
	var zombie := _zombie_with_word("code")
	manager.zombie_spawned.emit(zombie)

	zombie.take_damage(1.0)
	assert_gt(zombie.zombie_sprite.self_modulate.r, 1.0)

	await wait_seconds(0.3)
	assert_eq(zombie.zombie_sprite.self_modulate, Color.WHITE)


func _bursts() -> Array[CPUParticles2D]:
	var found: Array[CPUParticles2D] = []
	for child in feedback.get_children():
		if child is CPUParticles2D:
			found.append(child)
	return found


func test_killing_hit_spawns_a_death_burst_where_the_zombie_was() -> void:
	var zombie := _zombie_with_word("code")
	zombie.global_position = Vector2(300, 200)
	manager.zombie_spawned.emit(zombie)

	zombie.take_damage(9999.0)

	assert_eq(_bursts().size(), 1)
	assert_eq(_bursts()[0].global_position, Vector2(300, 200))


func test_non_lethal_hit_does_not_spawn_a_death_burst() -> void:
	var zombie := _zombie_with_word("code")
	manager.zombie_spawned.emit(zombie)

	zombie.take_damage(1.0)

	assert_eq(_bursts().size(), 0)


func test_death_burst_cleans_itself_up() -> void:
	feedback.spawn_death_burst(Vector2.ZERO, Color.WHITE)
	await wait_seconds(0.8)
	assert_eq(_bursts().size(), 0)


func test_reduce_flashing_turns_off_the_hit_flash() -> void:
	SettingsState.reduce_flashing = true
	var zombie := _zombie_with_word("code")
	manager.zombie_spawned.emit(zombie)

	zombie.take_damage(1.0)

	assert_eq(zombie.zombie_sprite.self_modulate, Color.WHITE)


func test_respawned_zombie_is_only_connected_once() -> void:
	var zombie := _zombie_with_word("code")
	manager.zombie_spawned.emit(zombie)
	manager.zombie_spawned.emit(zombie)
	assert_eq(zombie.damaged.get_connections().size(), 1)


func test_firing_without_ammo_shows_the_reload_prompt() -> void:
	weapon.attempted_fire_without_ammunition.emit()

	assert_eq(_popups().size(), 1)
	assert_eq(_popups()[0].text, "TYPE A WORD TO RELOAD")
	assert_ne(ammo_panel.modulate, Color.WHITE)


func test_reload_prompt_does_not_spam_on_repeated_clicks() -> void:
	weapon.attempted_fire_without_ammunition.emit()
	weapon.attempted_fire_without_ammunition.emit()
	weapon.attempted_fire_without_ammunition.emit()
	assert_eq(_popups().size(), 1)
