class_name MissionSuccess
extends CanvasLayer

# emitted on Next Mission, the owning mission handles cleanup
# and the actual scene change so this menus stays reusable across missions
signal next_mission_requested

# emitted on Return To Hub, the owning mission handles cleanup
# and the actual scene change so this menu stays reusable across missions
signal return_home_requested

# emitted on Replay, the owning mission handles cleanup
# the scene restarts the owning mission
signal replay_requested

@onready var stats: Label = $CenterContainer/MenuPanel/MenuMargin/MenuList/Stats

func _ready() -> void:
	_display_stats(0)

func _display_stats(gold_amount: int) -> void:
	stats.text = """
		+%d Gold
		%d Zombies killed
		%.2f Health Remaining"""

func _on_next_mission_pressed() -> void:
	next_mission_requested.emit()

func _on_return_to_hub_pressed() -> void:
	return_home_requested.emit()

func _on_restart_pressed() -> void:
	replay_requested.emit()
