extends CanvasLayer

signal closed

@onready var content_2: Label = $CenterContainer/MenuPanel/MenuMargin/MenuList/MenuPanel2/ScrollContainer/VBoxContainer/Content2
@onready var content_4: Label = $CenterContainer/MenuPanel/MenuMargin/MenuList/MenuPanel2/ScrollContainer/VBoxContainer/Content4

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Audio.play("click")
		closed.emit()
		get_viewport().set_input_as_handled()


func _ready() -> void:
	var shoot_key: String = SettingsState.get_fire_label()
	
	var supply_1_keycode: int = SettingsState.get_supply_key(0)
	var supply_2_keycode: int = SettingsState.get_supply_key(1)
	var supply_3_keycode: int = SettingsState.get_supply_key(2)
	
	var supply_1: String = OS.get_keycode_string(supply_1_keycode)
	var supply_2: String = OS.get_keycode_string(supply_2_keycode)
	var supply_3: String = OS.get_keycode_string(supply_3_keycode)
	
	content_2.text = "Use your mouse to aim. Press %s to Fire. You must aim and shoot the zombies.\n" % [shoot_key]
	content_4.text = "You can bring up to 3 supplies into a mission. Press %s, %s or %s to call the corresponding supply. After the crate lands, type its word before the timer runs out to activate it.\n" % [supply_1, supply_2, supply_3]

func _on_back_button_pressed() -> void:
	Audio.play("click")
	closed.emit()
