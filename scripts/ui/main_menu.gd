extends Control

func _ready() -> void:
	Audio.play("main_music")

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if get_viewport().gui_get_hovered_control() is Button:
				Audio.play("click")
			else:
				Audio.play("thud")

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")


func _on_quit_button_pressed() -> void:
	#Audio.play("click")
	get_tree().quit()
