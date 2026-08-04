extends Node2D

@export var crosshair_texture: Texture2D

@onready var ammo_system: AmmoSystem = $AmmoSystem
@onready var ammo_label: Label = %AmmoLabel
@onready var ammo_bar: ProgressBar = %AmmoBar
@onready var typing_controller: Node = $TypingController
@onready var weapon_controller: WeaponController = $World/WeaponController
@onready var projectile_container: Node2D = $World/ProjectileContainer


func _ready() -> void:
	# set centered custom cursor image if provided
	if crosshair_texture != null:
		Input.set_custom_mouse_cursor(
			crosshair_texture,
			Input.CURSOR_ARROW,
			Vector2(
				crosshair_texture.get_width() / 2.0,
				crosshair_texture.get_height() / 2.0
			)
		)
		
	# connect ammo signal and set initial display state
	ammo_system.ammunition_changed.connect(
		_on_ammunition_changed
	)
	_on_ammunition_changed(
		ammo_system.current_ammo,
		ammo_system.maximum_ammo
	)
	
	# inject dependencies and connect weapon feedback
	weapon_controller.configure(
		ammo_system,
		projectile_container
	)
	weapon_controller.attempted_fire_without_ammunition.connect(
		_on_attempted_fire_without_ammunition
	)
	
	typing_controller.word_completed.connect(
		_on_typing_word_completed
	)


func _exit_tree() -> void:
	# reset custom cursor back to system default on scene exit
	Input.set_custom_mouse_cursor(null)


func _on_return_home_base_button_pressed() -> void:
	# return to main home base scene
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")


func _on_ammunition_changed(
	current_ammo: int,
	maximum_ammo: int
) -> void:
	# update hud label and progress bar values
	ammo_label.text = "AMMUNITION: %d / %d" % [
		current_ammo,
		maximum_ammo
	]

	ammo_bar.min_value = 0
	ammo_bar.max_value = maximum_ammo
	ammo_bar.value = current_ammo


func _unhandled_input(event: InputEvent) -> void:
	# check for left mouse click and attempt to fire weapon toward cursor
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		weapon_controller.try_fire(
			get_global_mouse_position()
		)

	# debug inputs to manually manipulate ammo system
	elif event.is_action_pressed("debug_add_ammo"):
		ammo_system.add_ammunition(1)

	elif event.is_action_pressed("debug_use_ammo"):
		ammo_system.consume_ammunition(1)

	elif event.is_action_pressed(
		"debug_increase_ammo_capacity"
	):
		ammo_system.set_maximum_ammunition(
			ammo_system.maximum_ammo + 4
		)

	elif event.is_action_pressed("debug_reset_ammo"):
		ammo_system.reset_ammunition()
		print("Ammunition reset")

func _on_attempted_fire_without_ammunition() -> void:
	# todo: replace print with empty-click sfx (e.g., AudioStreamPlayer)
	print("Cannot fire: ammunition is empty")
	
	
func _on_typing_word_completed(word: String, ammunition_reward: int) -> void:
	var amount_added := ammo_system.add_ammunition(
		ammunition_reward
	)

	print(
		"Completed word: ",
		word,
		" | Ammunition added: ",
		amount_added
	)
