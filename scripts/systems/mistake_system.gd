class_name MistakeSystem
extends Node

@onready var ammo_system: AmmoSystem = $"../AmmoSystem"
@onready var typing_controller: Node = $"../TypingController"
@onready var weapon_controller: WeaponController = $"../World/WeaponController"
@onready var mistakes_label: Label = $"../HUD/HUDRoot/TypingPanel/MistakePanel/MistakeMargin/MistakesLabel"

const JAM_COOLDOWN = 2.0
var mistake_count = 0
var jam_time = JAM_COOLDOWN

func _ready() -> void:
	typing_controller.typing_mistake.connect(_typing_mistake)
	typing_controller.correct_stroke.connect(_correct_stroke)

func _process(delta: float) -> void:
	if weapon_controller.set_jammed:
		jam_time -= delta
		if jam_time <= 0.0:
			_reset_jam()

func _reset_jam():
	set_jam(false)
	count_check()
	jam_time = JAM_COOLDOWN

func _typing_mistake():
	mistake_count += 1
	count_check()
	ammo_system.consume_ammunition(1)

func _correct_stroke():
	mistake_count = 0
	count_check()

func count_check():
	print("consecutive count: " + str(mistake_count))
	mistakes_label.text = "MISTAKES: "+ str(mistake_count)+" / 3"
	if mistake_count >= 3:
		mistake_count = 0
		set_jam(true)

func set_jam(jam_state: bool):
	weapon_controller.set_jammed = jam_state
	if jam_state:
		print("JAMMED")
		mistakes_label.text = "JAMMED"
	else:
		print("UNJAMMED")
