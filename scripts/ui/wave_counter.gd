extends CanvasLayer

# small "WAVE 1 / 3" panel under the wall health bar

@onready var panel: PanelContainer = $Root/Panel
@onready var label: Label = $Root/Panel/Margin/Label

var _zombie_manager: ZombieManager


func _ready() -> void:
	panel.visible = false


func setup(zombie_manager: ZombieManager) -> void:
	_zombie_manager = zombie_manager
	zombie_manager.wave_started.connect(_on_wave_started)


static func wave_text(wave_number: int, total_waves: int) -> String:
	if total_waves <= 0:
		return "WAVE %d" % wave_number
	return "WAVE %d / %d" % [wave_number, total_waves]


# the total is read after start_mission() has worked out how many waves the player will see
func _on_wave_started(wave_number: int, _is_final_wave: bool) -> void:
	label.text = wave_text(wave_number, _zombie_manager._max_display_wave_number)
	panel.visible = true
