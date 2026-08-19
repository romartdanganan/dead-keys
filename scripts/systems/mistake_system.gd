class_name MistakeSystem
extends Node

@onready var ammo_system: AmmoSystem = $"../AmmoSystem"
@onready var typing_controller: Node = $"../TypingController"
@onready var weapon_controller: WeaponController = $"../World/WeaponController"
@onready var mistakes_label: Label = $"../HUD/HUDRoot/TypingPanel/MistakePanel/MistakeMargin/MistakesLabel"

# duration of a weapon jam in seconds
const JAM_COOLDOWN: float = 2.0

var mistake_count: int = 0
var jam_time: float = JAM_COOLDOWN


func _ready() -> void:
	typing_controller.typing_mistake.connect(_typing_mistake)
	typing_controller.correct_stroke.connect(_correct_stroke)


func _process(delta: float) -> void:
	# count down only while the weapon is jammed
	if weapon_controller.set_jammed:
		jam_time -= delta

		if jam_time <= 0.0:
			_reset_jam()


func _reset_jam() -> void:
	# restore the weapon and reset the jam timer
	set_jam(false)
	count_check()
	jam_time = JAM_COOLDOWN


func _typing_mistake() -> void:
	ammo_system.consume_ammunition(1) # made sure to always consume ammo at a mistake even when jammed

	# mistakes made during a jam do not build toward another jam
	if weapon_controller.set_jammed:
		return

	mistake_count += 1
	count_check()


func _correct_stroke() -> void:
	# typing during a jam should not change the jam display
	if weapon_controller.set_jammed:
		return

	# a correct keystroke breaks the consecutive mistake streak
	mistake_count = 0
	count_check()


func count_check() -> void:
	# update the counter and trigger a jam at three mistakes
	print("consecutive count: " + str(mistake_count))
	mistakes_label.text = "MISTAKES: " + str(mistake_count) + " / 3"

	if mistake_count >= 3:
		mistake_count = 0
		set_jam(true)


func set_jam(jam_state: bool) -> void:
	# update the weapon state and hud
	weapon_controller.set_jammed = jam_state

	if jam_state:
		print("JAMMED")
		mistakes_label.text = "JAMMED"
	else:
		print("UNJAMMED")
