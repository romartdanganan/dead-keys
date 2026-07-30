extends Node2D

@export var crosshair_texture: Texture2D


func _ready() -> void:
	if crosshair_texture != null:
		Input.set_custom_mouse_cursor(
			crosshair_texture,
			Input.CURSOR_ARROW,
			Vector2(
				crosshair_texture.get_width() / 2.0,
				crosshair_texture.get_height() / 2.0
			)
		)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null)


func _on_return_home_base_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")
