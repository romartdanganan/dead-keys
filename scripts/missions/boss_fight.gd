extends Node

# runs the tank fight: entrance, two phase changes and the finale
# each phase change gives the player a breather or a shortcut, so the fight is livelier but never harder

signal phase_changed(phase: int)
# the kill cinematic is over and the mission can show its result
signal finale_finished

const BossHealthBar := preload("res://scripts/ui/boss_health_bar.gd")
const WALKER_TYPE: EnemyTypeDef = preload("res://resources/enemies/walker.tres")
const RUNNER_TYPE: EnemyTypeDef = preload("res://resources/enemies/runner.tres")

const PHASE_2_FRACTION: float = 0.66
const PHASE_3_FRACTION: float = 0.33
# the tank stops to roar on each phase change, a free window to catch up on words
const STAGGER_SECONDS: float = 2.5
# helpers have short words, quick kills that refill ammo for the long boss words
const SUMMON_COUNT: int = 2
const SUMMON_SPREAD: float = 80.0
const SUMMON_BUCKETS: Array[int] = [1]
# phase 3 cracks the armour, knocking off a share of the health it has left
const ARMOUR_CRACK_SHARE: float = 1.0 / 3.0
const ENRAGED_SPEED_MULTIPLIER: float = 1.25
const ENRAGED_TINT: Color = Color(1.0, 0.65, 0.65)
const SCREEN_MARGIN: float = 60.0

# finale timings are in real seconds, the slow part lasts as long as the slowed death animation
const SLOW_MOTION_SCALE: float = 0.25
const FINALE_ZOOM: float = 1.8
const FINALE_ZOOM_IN_SECONDS: float = 0.6
const FINALE_SLOW_SECONDS: float = 2.8
const FINALE_ZOOM_OUT_SECONDS: float = 0.8
const FINALE_HOLD_SECONDS: float = 0.9
# endless keeps going after a boss, so it only gets a short slow motion
const QUICK_SLOW_MOTION_SECONDS: float = 0.9

enum Finale { NONE, SLOW_KILL, ZOOM_OUT }

# endless turns this off so killing a boss does not end the run
var ends_mission: bool = true
var boss: Zombie = null
var phase: int = 0
var finale_playing: bool = false
var _zombie_manager: ZombieManager
var _camera: Node
var _announcement: Node
var _base_speed: float = 0.0
var _speed_multiplier: float = 1.0
var _stagger_left: float = 0.0
var _slow_motion_left: float = 0.0
var _finale_stage: Finale = Finale.NONE
var _finale_left: float = 0.0


# camera and announcement are optional so GUT can run the fight without a mission scene
func setup(zombie_manager: ZombieManager, camera: Node = null, announcement: Node = null) -> void:
	_zombie_manager = zombie_manager
	_camera = camera
	_announcement = announcement
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)


func _on_zombie_spawned(zombie: Zombie) -> void:
	if boss != null or not BossHealthBar.is_boss(zombie.enemy_type):
		return
	boss = zombie
	phase = 1
	_speed_multiplier = 1.0
	# a private copy, so changing this tank's speed never edits the shared tank.tres
	zombie.enemy_type = zombie.enemy_type.duplicate()
	_base_speed = zombie.enemy_type.speed
	if not zombie.damaged.is_connected(_on_boss_damaged):
		zombie.damaged.connect(_on_boss_damaged)
	if not zombie.died.is_connected(_on_boss_died):
		zombie.died.connect(_on_boss_died)
	_announce("BOSS INCOMING")
	_shake(0.55)
	if _camera != null and _camera.has_method("zoom_pulse"):
		_camera.zoom_pulse(0.06, 0.8)
	phase_changed.emit(phase)


func _on_boss_damaged(zombie: Zombie) -> void:
	if zombie != boss or zombie.health <= 0.0:
		return
	var fraction := zombie.health / zombie.get_max_health()
	if phase == 1 and fraction <= PHASE_2_FRACTION:
		_enter_phase_2()
	elif phase == 2 and fraction <= PHASE_3_FRACTION:
		_enter_phase_3()


# phase 2 calls in cats
func _enter_phase_2() -> void:
	phase = 2
	_announce("THE TANK CALLS FOR HELP")
	_shake(0.45)
	_stagger()
	# deferred since this runs inside a bullet hit, where new hitboxes can't be set up
	_summon.call_deferred(WALKER_TYPE)
	phase_changed.emit(phase)


# phase 3 cracks the armour and calls in dogs
func _enter_phase_3() -> void:
	phase = 3
	_announce("ARMOUR CRACKED")
	_shake(0.6)
	boss.health *= 1.0 - ARMOUR_CRACK_SHARE
	_speed_multiplier = ENRAGED_SPEED_MULTIPLIER
	boss.zombie_sprite.modulate = ENRAGED_TINT
	_stagger()
	_summon.call_deferred(RUNNER_TYPE)
	phase_changed.emit(phase)


# one helper above the tank and one below so the word labels never stack
func _summon(type: EnemyTypeDef) -> void:
	if boss == null:
		return
	for i in SUMMON_COUNT:
		var side := -1.0 if i % 2 == 0 else 1.0
		var spot := boss.global_position + Vector2(side * SUMMON_SPREAD, side * SUMMON_SPREAD * 1.6)
		_zombie_manager.spawn_extra(type, _clamp_to_screen(spot), SUMMON_BUCKETS)


func _stagger() -> void:
	_stagger_left = STAGGER_SECONDS
	boss.enemy_type.speed = 0.0


func _on_boss_died(zombie: Zombie) -> void:
	if zombie != boss:
		return
	boss = null
	phase = 4
	_announce("BOSS DEFEATED")
	_shake(0.8)
	phase_changed.emit(phase)
	if ends_mission:
		_play_finale(zombie)
	else:
		Engine.time_scale = SLOW_MOTION_SCALE
		_slow_motion_left = QUICK_SLOW_MOTION_SECONDS


# zoom in on the slowed tank death, then _update_finale zooms out and finishes
func _play_finale(tank: Zombie) -> void:
	finale_playing = true
	_zombie_manager.stop_mission()
	# leftover words would only clutter the close up, those zombies drop on the zoom out anyway
	for zombie: Zombie in _zombie_manager.active_zombies:
		zombie.word_label.visible = false
	Engine.time_scale = SLOW_MOTION_SCALE
	if _camera != null and _camera.has_method("focus_on"):
		_camera.focus_on(tank.global_position, FINALE_ZOOM, FINALE_ZOOM_IN_SECONDS)
	_finale_stage = Finale.SLOW_KILL
	_finale_left = FINALE_SLOW_SECONDS


# counted in _process instead of awaited, so quitting mid cinematic leaves nothing waiting
func _update_finale(real_delta: float) -> void:
	if _finale_stage == Finale.NONE:
		return
	_finale_left -= real_delta
	if _finale_left > 0.0:
		return
	if _finale_stage == Finale.SLOW_KILL:
		# zoom out at normal speed while every other zombie drops
		Engine.time_scale = 1.0
		if _camera != null and _camera.has_method("reset_focus"):
			_camera.reset_focus(FINALE_ZOOM_OUT_SECONDS)
		_kill_remaining_zombies()
		_finale_stage = Finale.ZOOM_OUT
		_finale_left = FINALE_ZOOM_OUT_SECONDS + FINALE_HOLD_SECONDS
	else:
		_finale_stage = Finale.NONE
		finale_playing = false
		finale_finished.emit()


# every zombie left on screen plays its death animation together
func _kill_remaining_zombies() -> void:
	for zombie: Zombie in _zombie_manager.active_zombies.duplicate():
		zombie.take_damage(zombie.health + 1.0)


func _process(delta: float) -> void:
	# delta is scaled by time_scale, so divide to count real seconds
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	_update_finale(real_delta)
	if _slow_motion_left > 0.0:
		_slow_motion_left -= real_delta
		if _slow_motion_left <= 0.0:
			Engine.time_scale = 1.0
	if _stagger_left > 0.0 and boss != null:
		_stagger_left -= delta
		if _stagger_left <= 0.0:
			boss.enemy_type.speed = _base_speed * _speed_multiplier


func _exit_tree() -> void:
	# leaving mid finale must never leave the game in slow motion
	Engine.time_scale = 1.0


func _announce(text: String) -> void:
	if _announcement != null and _announcement.has_method("show_text"):
		_announcement.show_text(text)


func _shake(amount: float) -> void:
	if _camera != null and _camera.has_method("add_trauma"):
		_camera.add_trauma(amount)


func _clamp_to_screen(spot: Vector2) -> Vector2:
	var size := get_viewport().get_visible_rect().size
	return Vector2(clampf(spot.x, SCREEN_MARGIN, size.x - SCREEN_MARGIN), clampf(spot.y, SCREEN_MARGIN, size.y - SCREEN_MARGIN))
