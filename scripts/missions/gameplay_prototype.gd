extends Node2D


@export var crosshair_texture: Texture2D
@export var enemy_type: EnemyTypeDef = preload("res://resources/enemies/walker.tres")

@onready var ammo_system: AmmoSystem = $AmmoSystem
@onready var ammo_label: Label = %AmmoLabel
@onready var ammo_bar: ProgressBar = %AmmoBar
@onready var wall_health_label: Label = $HUD/HUDRoot/WallPanelAnchor/WallPanel/WallMargin/WallContent/WallHealthLabel
@onready var wall_health_bar: ProgressBar = $HUD/HUDRoot/WallPanelAnchor/WallPanel/WallMargin/WallContent/WallHealthBar
@onready var lives_label: Label = $HUD/HUDRoot/LivesPanel/LivesMargin/LivesContent/LivesLabel
@onready var life_icons: Array[TextureRect] = [
	$HUD/HUDRoot/LivesPanel/LivesMargin/LivesContent/LivesIcons/LifeIcon1,
	$HUD/HUDRoot/LivesPanel/LivesMargin/LivesContent/LivesIcons/LifeIcon2,
	$HUD/HUDRoot/LivesPanel/LivesMargin/LivesContent/LivesIcons/LifeIcon3,
]
@onready var typing_controller: Node = $TypingController
@onready var weapon_controller: WeaponController = $World/WeaponController
@onready var projectile_container: Node2D = $World/ProjectileContainer
@onready var spawn_points: Array[Marker2D] = [$World/EnemySpawnArea/SpawnLeftBoundary, $World/EnemySpawnArea/SpawnCentreGuide, $World/EnemySpawnArea/SpawnRightBoundary]
@onready var wall_target: Marker2D = $World/WallAttackLine
@onready var status_timer: Timer = $StatusTimer

var zombie_manager: ZombieManager

# base wall HP — overridden by the Fortified Wall upgrade (#25) in _ready()
var WALL_MAX_HEALTH: float = 100.0

var wall_health: float = WALL_MAX_HEALTH

# Extra Life upgrade (#25): mission starts with this many lives; wall resets
# to 50% health and the mission continues each time a life is spent, per
# GDD §2.5's "extra lives" design note. Mission only ends when lives hit 0.
var lives_remaining: int = 1

func _ready() -> void:
	_apply_upgrades()
	_setup_cursor()
	_setup_ammo_hud()
	_setup_wall_hud()
	_setup_lives_hud()
	_setup_weapon()
	_setup_typing()
	_start_mission()


# reads Fortified Wall and Extra Life upgrade values (#25) before any HUD
# or gameplay values that depend on them are set up. Fire Rate, Bullet
# Damage, and Magazine Capacity are applied in their own _setup_* functions
# below since they need the relevant node to already be ready.
func _apply_upgrades() -> void:
	WALL_MAX_HEALTH = UpgradeState.get_upgrade_value("fortified_wall")
	wall_health = WALL_MAX_HEALTH
	lives_remaining = UpgradeState.get_upgrade_value("extra_life")

func _exit_tree() -> void:
	# reset custom cursor back to system default on scene exit
	Input.set_custom_mouse_cursor(null)

func _unhandled_input(event: InputEvent) -> void:
	# check for left mouse click and attempt to fire weapon toward cursor
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		weapon_controller.try_fire(get_global_mouse_position())

	# debug inputs to manually manipulate ammo system
	elif event.is_action_pressed("debug_add_ammo"):
		ammo_system.add_ammunition(1)
	elif event.is_action_pressed("debug_use_ammo"):
		ammo_system.consume_ammunition(1)
	elif event.is_action_pressed("debug_increase_ammo_capacity"):
		ammo_system.set_maximum_ammunition(ammo_system.maximum_ammo + 4)
	elif event.is_action_pressed("debug_reset_ammo"):
		ammo_system.reset_ammunition()
		print("Ammunition reset")


func _setup_cursor() -> void:
	if crosshair_texture == null:
		return
	Input.set_custom_mouse_cursor(
		crosshair_texture,
		Input.CURSOR_ARROW,
		Vector2(crosshair_texture.get_width() / 2.0, crosshair_texture.get_height() / 2.0)
	)

func _setup_ammo_hud() -> void:
	# Magazine Capacity upgrade (#25)
	ammo_system.set_maximum_ammunition(UpgradeState.get_upgrade_value("magazine_capacity"))

	ammo_system.ammunition_changed.connect(_on_ammunition_changed)
	_on_ammunition_changed(ammo_system.current_ammo, ammo_system.maximum_ammo)

func _setup_wall_hud() -> void:
	_update_wall_hud()

func _setup_lives_hud() -> void:
	_update_lives_hud()

func _setup_weapon() -> void:
	weapon_controller.configure(ammo_system, projectile_container)
	weapon_controller.attempted_fire_without_ammunition.connect(_on_attempted_fire_without_ammunition)

	# Fire Rate upgrade (#25): shots/s -> cooldown seconds
	var shots_per_second: float = UpgradeState.get_upgrade_value("fire_rate")
	weapon_controller.fire_cooldown = 1.0 / shots_per_second

	# Bullet Damage upgrade (#25), applied to each projectile on fire
	weapon_controller.bullet_damage = UpgradeState.get_upgrade_value("bullet_damage")

func _setup_typing() -> void:
	typing_controller.word_completed.connect(_on_typing_word_completed)

func _start_mission() -> void:
	var mission := _build_mission_config()

	zombie_manager = ZombieManager.new()
	add_child(zombie_manager)
	zombie_manager.mission_config = mission
	zombie_manager.wall_target = wall_target
	zombie_manager.spawn_points = spawn_points
	zombie_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)

	status_timer.timeout.connect(_on_status_timer_timeout)

	zombie_manager.start_mission()

	print("Mission started: ", mission.mission_name)
	print("Wave 1: 2 Walkers | Wave 2: 1 Walker")
	print("Type any active word shown above a zombie.")

func _build_mission_config() -> MissionConfigDef:
	var wave_1 := WaveEntry.new()
	wave_1.enemy_type = enemy_type
	wave_1.count = 5
	wave_1.spawn_interval = 5
	wave_1.start_delay = 0.5

	var wave_2 := WaveEntry.new()
	wave_2.enemy_type = enemy_type
	wave_2.count = 1
	wave_2.spawn_interval = 5
	wave_2.start_delay = 0.5

	var mission := MissionConfigDef.new()
	mission.mission_id = "mission_1_multi_wave_test"
	mission.mission_name = "Defend the Suburbs - Wave 1 & 2"
	mission.waves = [wave_1, wave_2]
	mission.base_coin_reward = 50
	return mission


func _on_ammunition_changed(current_ammo: int, maximum_ammo: int) -> void:
	ammo_label.text = "AMMUNITION: %d / %d" % [current_ammo, maximum_ammo]
	ammo_bar.min_value = 0
	ammo_bar.max_value = maximum_ammo
	ammo_bar.value = current_ammo

func _on_attempted_fire_without_ammunition() -> void:
	# todo: replace print with empty-click sfx (e.g., AudioStreamPlayer)
	print("Cannot fire: ammunition is empty")



func _on_typing_word_completed(word: String, ammunition_reward: int) -> void:
	var amount_added := ammo_system.add_ammunition(ammunition_reward)
	print("Completed word: ", word, " | Ammunition added: ", amount_added)


func _on_status_timer_timeout() -> void:
	print("Active zombies: ", zombie_manager.active_zombies.size())

func _on_zombie_spawned(spawned_zombie: Zombie) -> void:
	var word_label: RichTextLabel = spawned_zombie.get_node("WordLabel")
	typing_controller.register_target(spawned_zombie, word_label)

	spawned_zombie.died.connect(
		func(dead_zombie: Zombie) -> void:
			typing_controller.unregister_target(dead_zombie)
	)
	spawned_zombie.damaged.connect(_on_zombie_damaged)
	spawned_zombie.wall_hit.connect(_on_wall_hit)

func _on_zombie_damaged(damaged_zombie: Zombie) -> void:
	print("Zombie health now: ", damaged_zombie.health)

func _on_wall_hit(damage: float) -> void:
	wall_health = max(wall_health - damage, 0.0)
	_update_wall_hud()
	print("Wall hit for ", damage, " damage. Wall health: ", wall_health)
	if wall_health <= 0.0:
		_spend_life()

func _spend_life() -> void:
	lives_remaining -= 1
	_update_lives_hud()

	if lives_remaining > 0:
		print("Wall destroyed. Life lost, ", lives_remaining, " remaining. Wall reset to 50%.")
		wall_health = WALL_MAX_HEALTH * 0.5
		_update_wall_hud()
	else:
		print("Wall destroyed. No lives remaining. Returning to home base.")
		return_to_home_base()

func _on_all_waves_cleared() -> void:
	print("Mission complete. Returning to home base.")
	return_to_home_base()


func _on_return_home_base_button_pressed() -> void:
	# NOTE: kept this exact function name — it's very likely connected to a
	# Button's `pressed` signal via the editor's Signals panel, not visible
	# in this file. Renaming it would break that connection silently.
	return_to_home_base()

func return_to_home_base() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")

func _update_wall_hud() -> void:
	wall_health_label.text = "WALL HEALTH: %d / %d" % [int(wall_health), int(WALL_MAX_HEALTH)]
	wall_health_bar.min_value = 0
	wall_health_bar.max_value = WALL_MAX_HEALTH
	wall_health_bar.value = wall_health

func _update_lives_hud() -> void:
	lives_label.text = "LIVES: %d" % lives_remaining
	for i in life_icons.size():
		# lit for lives still remaining, dimmed for lives already spent
		life_icons[i].modulate.a = 1.0 if i < lives_remaining else 0.27
