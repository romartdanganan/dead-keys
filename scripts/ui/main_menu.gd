extends Control

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
var settings_menu: Node = null

const HOW_TO_PLAY_SCENE := preload("res://scenes/ui/how_to_play.tscn")
var how_to_play_overlay: Node = null

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


func _on_settings_button_pressed() -> void:
	if settings_menu != null:
		return
	settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(settings_menu)
	settings_menu.closed.connect(_on_settings_menu_closed)


func _on_settings_menu_closed() -> void:
	settings_menu.queue_free()
	settings_menu = null


func _on_how_to_play_pressed() -> void:
	if how_to_play_overlay != null:
		return
	how_to_play_overlay = HOW_TO_PLAY_SCENE.instantiate()
	add_child(how_to_play_overlay)
	how_to_play_overlay.closed.connect(_on_how_to_play_overlay_closed)

func _on_how_to_play_overlay_closed() -> void:
	how_to_play_overlay.queue_free()
	how_to_play_overlay = null
