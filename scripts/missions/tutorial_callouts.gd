extends Node

# shows each tutorial hint once per save, the first time it becomes relevant (GDD 5.1, 2.7)

const TUTORIAL_CALLOUT_SCENE := preload("res://scenes/ui/tutorial_callout.tscn")
const AbilityCatalogScript := preload("res://scripts/resources/ability_catalog.gd")

# one line per enemy type, a new type only needs an entry here
const ENEMY_CALLOUTS: Dictionary = {
	"runner": "NEW ENEMY: Runner. Fast but fragile, with short words",
	"medic": "NEW ENEMY: Medic. Heals nearby zombies, take it out first",
	"brute": "NEW ENEMY: Brute. Slow and tough, with long words",
	"commander": "NEW ENEMY: Commander. Speeds up the zombies around it",
	# boss callout uses BOSS instead of NEW ENEMY so it stands out
	"tank": "BOSS: Tank. Huge health and long words, keep firing",
}

var _banner: CanvasLayer
var _weapon_controller: WeaponController


# takes the pieces it listens to rather than the whole mission so GUT can test it
func setup(typing_controller: TypingController, zombie_manager: ZombieManager, weapon_controller: WeaponController) -> void:
	_banner = TUTORIAL_CALLOUT_SCENE.instantiate()
	add_child(_banner)
	_weapon_controller = weapon_controller
	typing_controller.word_completed.connect(_on_word_completed)
	zombie_manager.wave_started.connect(_on_wave_started)
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)
	AbilityState.charged_changed.connect(_on_charged_changed)


func get_banner() -> CanvasLayer:
	return _banner


static func enemy_callout_text(enemy_id: String) -> String:
	return ENEMY_CALLOUTS.get(enemy_id, "")


# polled because the mistake system has no jam signal to listen to
func _process(_delta: float) -> void:
	if _weapon_controller != null and _weapon_controller.set_jammed:
		_try_show("first_jam", "3 mistakes in a row jams your gun for a moment")


func _on_wave_started(wave_number: int, _is_final_wave: bool) -> void:
	if wave_number != 1:
		return
	_try_show("type_to_load", "Type the word above a zombie to load ammo")
	if _has_any_supply():
		_try_show("call_supply", "Press %s to call in a supply crate" % _supply_keys_text())


func _on_word_completed(_word: String, _ammunition_reward: int) -> void:
	_try_show("aim_and_fire", "Aim with the mouse and press %s to fire" % SettingsState.get_fire_label())


func _on_charged_changed(is_charged: bool) -> void:
	if not is_charged:
		return
	var ability := AbilityCatalogScript.get_ability(AbilityState.equipped_ability_id)
	_try_show("ability_charged", "5 kills in a row! Your next shot fires %s" % ability.get("display_name", "your ability"))


func _on_zombie_spawned(zombie: Zombie) -> void:
	if zombie.enemy_type == null:
		return
	var enemy_id := zombie.enemy_type.enemy_id
	var text := enemy_callout_text(enemy_id)
	if not text.is_empty():
		_try_show("enemy_" + enemy_id, text)


func _try_show(callout_id: String, text: String) -> void:
	if TutorialState.has_seen(callout_id):
		return
	TutorialState.mark_seen(callout_id)
	_banner.show_callout(text)


func _has_any_supply() -> bool:
	for i in 3:
		if not SupplyState.get_slot(i).is_empty():
			return true
	return false


func _supply_keys_text() -> String:
	var keys: Array[String] = []
	for i in 3:
		keys.append(OS.get_keycode_string(SettingsState.get_supply_key(i)))
	return ", ".join(keys)
