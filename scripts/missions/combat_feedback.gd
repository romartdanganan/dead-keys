extends Node2D

# hit flash, death burst, floating ammo popups and the out of ammo prompt, kept out of mission_1.gd

const HIT_FLASH_COLOUR: Color = Color(2.5, 2.5, 2.5)
const HIT_FLASH_SECONDS: float = 0.12
const POPUP_RISE: float = 40.0
const POPUP_SECONDS: float = 0.9
const POPUP_OFFSET: Vector2 = Vector2(0, -95)
const AMMO_COLOUR: Color = Color(1.0, 0.85, 0.3)
const EMPTY_COLOUR: Color = Color(1.0, 0.35, 0.3)
const OUT_OF_AMMO_COOLDOWN: float = 1.0
const DEATH_BURST_SECONDS: float = 0.45
const DEATH_BURST_PARTICLES: int = 16

var _typing_controller: TypingController
var _ammo_system: AmmoSystem
var _ammo_panel: Control
var _previous_ammo: int = 0
var _last_ammo_gain: int = 0
var _out_of_ammo_cooldown: float = 0.0


func _ready() -> void:
	# draw popups above zombies and their word labels
	z_index = 150


# takes the pieces it listens to rather than the whole mission so GUT can test it
func setup(typing_controller: TypingController, zombie_manager: ZombieManager, weapon_controller: WeaponController, ammo_system: AmmoSystem, ammo_panel: Control) -> void:
	_typing_controller = typing_controller
	_ammo_system = ammo_system
	_ammo_panel = ammo_panel
	_previous_ammo = ammo_system.current_ammo
	ammo_system.ammunition_changed.connect(_on_ammunition_changed)
	typing_controller.word_completed.connect(_on_word_completed)
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)
	weapon_controller.attempted_fire_without_ammunition.connect(_on_fired_without_ammo)


static func ammo_popup_text(ammo_gained: int) -> String:
	if ammo_gained <= 0:
		return "AMMO FULL"
	return "+%d AMMO" % ammo_gained


func _process(delta: float) -> void:
	_out_of_ammo_cooldown = maxf(_out_of_ammo_cooldown - delta, 0.0)


# pooled zombies are reused, so the guard stops a second connection stacking up
func _on_zombie_spawned(zombie: Zombie) -> void:
	if not zombie.damaged.is_connected(_on_zombie_damaged):
		zombie.damaged.connect(_on_zombie_damaged)


# self_modulate so the flash never fights the freeze tint or type colour on modulate
func _on_zombie_damaged(zombie: Zombie) -> void:
	var sprite := zombie.zombie_sprite
	if zombie.has_meta("hit_flash_tween"):
		var old_tween: Tween = zombie.get_meta("hit_flash_tween")
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
	# the reduce flashing setting turns the hit flash off entirely
	if not SettingsState.reduce_flashing:
		sprite.self_modulate = HIT_FLASH_COLOUR
		var tween := create_tween()
		tween.tween_property(sprite, "self_modulate", Color.WHITE, HIT_FLASH_SECONDS)
		zombie.set_meta("hit_flash_tween", tween)

	# damaged fires before the zombie dies and is pooled off-screen, so it's still in place here
	if zombie.health <= 0.0:
		var colour := zombie.enemy_type.silhouette_modulate if zombie.enemy_type != null else Color.WHITE
		spawn_death_burst(zombie.global_position, colour)


# public so a future sprite death animation can call it when the animation starts
func spawn_death_burst(at: Vector2, colour: Color) -> CPUParticles2D:
	var burst := CPUParticles2D.new()
	burst.one_shot = true
	burst.amount = DEATH_BURST_PARTICLES
	burst.lifetime = DEATH_BURST_SECONDS
	burst.explosiveness = 1.0
	burst.spread = 180.0
	burst.gravity = Vector2.ZERO
	burst.initial_velocity_min = 60.0
	burst.initial_velocity_max = 140.0
	burst.damping_min = 80.0
	burst.damping_max = 120.0
	burst.scale_amount_min = 3.0
	burst.scale_amount_max = 5.0
	# fades the particles out over their short life so the burst never hides a word
	var fade := Gradient.new()
	fade.set_color(0, colour)
	fade.set_color(1, Color(colour, 0.0))
	burst.color_ramp = fade
	burst.global_position = at
	add_child(burst)
	burst.emitting = true
	get_tree().create_timer(DEATH_BURST_SECONDS + 0.2, false).timeout.connect(burst.queue_free)
	return burst


func _on_ammunition_changed(current_ammo: int, _maximum_ammo: int) -> void:
	_last_ammo_gain = current_ammo - _previous_ammo
	_previous_ammo = current_ammo


# the mission adds the ammo before this runs, so _last_ammo_gain is what was really added
func _on_word_completed(word: String, _ammunition_reward: int) -> void:
	var target := _find_target_with_word(word)
	if target == null:
		return
	var colour := AMMO_COLOUR if _last_ammo_gain > 0 else EMPTY_COLOUR
	_spawn_popup(ammo_popup_text(_last_ammo_gain), target.global_position + POPUP_OFFSET, colour)
	_last_ammo_gain = 0


# the finished word is still on its zombie while word_completed is being emitted
func _find_target_with_word(word: String) -> Node2D:
	for target_data in _typing_controller.active_targets:
		if target_data["word"] == word and target_data.get("kind", "zombie") == "zombie":
			var target = target_data["target"]
			if is_instance_valid(target) and target is Node2D:
				return target
	return null


func _on_fired_without_ammo() -> void:
	if _out_of_ammo_cooldown > 0.0:
		return
	_out_of_ammo_cooldown = OUT_OF_AMMO_COOLDOWN
	_spawn_popup("TYPE A WORD TO RELOAD", get_global_mouse_position() + Vector2(0, -30), EMPTY_COLOUR)
	if _ammo_panel != null and not SettingsState.reduce_flashing:
		_ammo_panel.modulate = EMPTY_COLOUR
		create_tween().tween_property(_ammo_panel, "modulate", Color.WHITE, 0.5)


func _spawn_popup(text: String, at: Vector2, colour: Color) -> Label:
	var popup := Label.new()
	popup.text = text
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.add_theme_font_size_override("font_size", 24)
	popup.add_theme_color_override("font_color", colour)
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 6)
	add_child(popup)
	# centre the text on the point it belongs to
	popup.position = at - Vector2(popup.get_minimum_size().x / 2.0, 0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - POPUP_RISE, POPUP_SECONDS)
	tween.tween_property(popup, "modulate:a", 0.0, POPUP_SECONDS).set_delay(POPUP_SECONDS * 0.4)
	tween.chain().tween_callback(popup.queue_free)
	return popup
