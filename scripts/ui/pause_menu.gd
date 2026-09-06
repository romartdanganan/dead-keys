class_name PauseMenu
extends CanvasLayer

# emitted on Resume or Escape, the owning mission handles unpausing and cleanup
signal resume_requested

# emitted on Return To Hub, the owning mission handles unpausing, cleanup,
# and the actual scene change so this menu stays reusable across missions
signal return_home_requested


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_return_home_button_pressed() -> void:
	return_home_requested.emit()
