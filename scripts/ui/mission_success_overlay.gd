class_name MissionSuccess
extends CanvasLayer

# emitted on Resume or Escape, the owning mission handles unpausing and cleanup
signal next_mission_requested

# emitted on Return To Hub, the owning mission handles unpausing, cleanup,
# and the actual scene change so this menu stays reusable across missions
signal return_home_requested


func _unhandled_input(event: InputEvent) -> void:
	pass

func _on_next_mission_pressed() -> void:
	next_mission_requested.emit()

func _on_return_to_hub_pressed() -> void:
	return_home_requested.emit()
