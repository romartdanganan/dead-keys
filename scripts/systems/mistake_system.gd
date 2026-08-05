class_name MistakeSystem
extends Node

@onready var ammo_system: AmmoSystem = $AmmoSystem
@onready var typing_controller: Node = $TypingController
@onready var weapon_controller: WeaponController = $World/WeaponController

var mistake_count = 0

func _ready() -> void:
	print("script ready")
	typing_controller.typing_mistake.connect(_typing_mistake)
	typing_controller.correct_stroke.connect(_correct_stroke)

func _typing_mistake():
	mistake_count += 1
	print("consecutive count: " + str(mistake_count))
	count_check()
	ammo_system.consume_ammunition(1)

func _correct_stroke():
	mistake_count = 0
	print("consecutive count: " + str(mistake_count))

func count_check():
	if mistake_count >= 3:
		print("JAMMED")
