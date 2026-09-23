class_name SettingsMenu
extends CanvasLayer

# emitted on Back or Escape, whichever screen instanced this frees it, same
# delegation pattern as PauseMenu's resume_requested/return_home_requested (#44)
signal closed

# unique names so restyling the layout doesn't break these paths
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var mistake_toggle: CheckButton = %MistakeSystemToggle


func _ready() -> void:
	# reflect current SettingsState values, this instance may be opened
	# fresh from three different screens so it can't assume its own defaults
	master_slider.value = SettingsState.master_volume
	music_slider.value = SettingsState.music_volume
	sfx_slider.value = SettingsState.sfx_volume
	mistake_toggle.button_pressed = SettingsState.mistake_system_enabled


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func _on_master_slider_value_changed(value: float) -> void:
	SettingsState.set_master_volume(value)


func _on_music_slider_value_changed(value: float) -> void:
	SettingsState.set_music_volume(value)


func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsState.set_sfx_volume(value)


func _on_mistake_system_toggle_toggled(toggled_on: bool) -> void:
	SettingsState.set_mistake_system_enabled(toggled_on)


func _on_back_button_pressed() -> void:
	closed.emit()
