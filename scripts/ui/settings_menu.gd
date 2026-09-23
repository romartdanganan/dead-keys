class_name SettingsMenu
extends CanvasLayer

# emitted on Back or Escape, whichever screen instanced this frees it, same
# delegation pattern as PauseMenu's resume_requested/return_home_requested
signal closed

# unique names so restyling the layout doesn't break these paths
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_value_label: Label = %MasterValueLabel
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SFXValueLabel
@onready var mistake_toggle: CheckButton = %MistakeSystemToggle
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption


func _ready() -> void:
	# no_signal setters so loading current values doesn't re-save every control
	master_slider.set_value_no_signal(SettingsState.master_volume)
	music_slider.set_value_no_signal(SettingsState.music_volume)
	sfx_slider.set_value_no_signal(SettingsState.sfx_volume)
	mistake_toggle.set_pressed_no_signal(SettingsState.mistake_system_enabled)
	_update_volume_labels()
	_populate_display_options()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		closed.emit()
		get_viewport().set_input_as_handled()


func _populate_display_options() -> void:
	window_mode_option.clear()
	window_mode_option.add_item("WINDOWED")
	window_mode_option.add_item("FULLSCREEN")
	window_mode_option.select(1 if SettingsState.fullscreen else 0)

	resolution_option.clear()
	for window_size in SettingsState.RESOLUTIONS:
		resolution_option.add_item("%d x %d" % [window_size.x, window_size.y])
	resolution_option.select(SettingsState.resolution_index)

	# resolution only matters in windowed mode
	resolution_option.disabled = SettingsState.fullscreen

	# display changes don't apply while running inside the editor's
	# embedded game window, disable both controls and say why
	if OS.has_feature("editor"):
		window_mode_option.disabled = true
		resolution_option.disabled = true
		%DisplayHintLabel.text = "Display options are not available inside the editor. Run the game in a separate window or export a build to use these settings."


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % roundi(master_slider.value * 100)
	music_value_label.text = "%d%%" % roundi(music_slider.value * 100)
	sfx_value_label.text = "%d%%" % roundi(sfx_slider.value * 100)


func _on_master_slider_value_changed(value: float) -> void:
	SettingsState.set_master_volume(value)
	_update_volume_labels()


func _on_music_slider_value_changed(value: float) -> void:
	SettingsState.set_music_volume(value)
	_update_volume_labels()


func _on_sfx_slider_value_changed(value: float) -> void:
	SettingsState.set_sfx_volume(value)
	_update_volume_labels()


func _on_mistake_system_toggle_toggled(toggled_on: bool) -> void:
	SettingsState.set_mistake_system_enabled(toggled_on)


func _on_window_mode_option_item_selected(index: int) -> void:
	SettingsState.set_fullscreen(index == 1)
	resolution_option.disabled = SettingsState.fullscreen


func _on_resolution_option_item_selected(index: int) -> void:
	SettingsState.set_resolution_index(index)


func _on_back_button_pressed() -> void:
	closed.emit()
