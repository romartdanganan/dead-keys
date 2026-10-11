class_name SettingsMenu
extends CanvasLayer

signal closed

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_value_label: Label = %MasterValueLabel
@onready var music_value_label: Label = %MusicValueLabel
@onready var sfx_value_label: Label = %SFXValueLabel
@onready var mistake_toggle: CheckButton = %MistakeSystemToggle
@onready var reduce_flashing_toggle: CheckButton = %ReduceFlashingToggle
@onready var window_mode_option: OptionButton = %WindowModeOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var fire_button: Button = %FireButton
@onready var ability_button: Button = %AbilityButton
@onready var supply_button_1: Button = %Supply1Button
@onready var supply_button_2: Button = %Supply2Button
@onready var supply_button_3: Button = %Supply3Button

# -1 = not listening. 10 = fire slot, 11 = ability slot, 0/1/2 = supply slots
var _listening_slot: int = -1
const FIRE_SLOT := 10
const ABILITY_SLOT := 11

const BLOCKED_UNICODE_START := 97
const BLOCKED_UNICODE_END   := 122

var _all_bind_buttons: Array[Button]
var supply_buttons: Array[Button]


func _ready() -> void:
	supply_buttons = [supply_button_1, supply_button_2, supply_button_3]
	_all_bind_buttons = [fire_button, ability_button, supply_button_1, supply_button_2, supply_button_3]
	master_slider.set_value_no_signal(SettingsState.master_volume)
	music_slider.set_value_no_signal(SettingsState.music_volume)
	sfx_slider.set_value_no_signal(SettingsState.sfx_volume)
	mistake_toggle.set_pressed_no_signal(SettingsState.mistake_system_enabled)
	reduce_flashing_toggle.set_pressed_no_signal(SettingsState.reduce_flashing)
	_update_volume_labels()
	_populate_display_options()
	_refresh_bind_buttons()


# rebind capture lives in _input since it runs before the GUI, clicks landing
# on a button or panel never reach _unhandled_input
func _input(event: InputEvent) -> void:
	if _listening_slot == -1:
		return

	var is_key: bool = event is InputEventKey and event.pressed and not event.echo
	var is_mouse: bool = event is InputEventMouseButton and event.pressed

	if is_key and event.physical_keycode == KEY_ESCAPE:
		_cancel_listen()
	elif is_key or is_mouse:
		_try_apply_binding(event)

	# swallow everything while listening, including releases and motion
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Audio.play("click")
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

	resolution_option.disabled = SettingsState.fullscreen

	if OS.has_feature("editor"):
		window_mode_option.disabled = true
		resolution_option.disabled = true
		%DisplayHintLabel.text = "Display options are not available inside the editor. Run the game in a separate window or export a build to use these settings."


func _refresh_bind_buttons() -> void:
	fire_button.text = SettingsState.get_fire_label()
	ability_button.text = SettingsState.get_ability_label()
	for i in supply_buttons.size():
		var keycode := SettingsState.get_supply_key(i)
		supply_buttons[i].text = OS.get_keycode_string(keycode)


func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % roundi(master_slider.value * 100)
	music_value_label.text = "%d%%" % roundi(music_slider.value * 100)
	sfx_value_label.text = "%d%%" % roundi(sfx_slider.value * 100)


func _on_fire_bind_pressed() -> void:
	_start_listen(FIRE_SLOT)


func _on_ability_bind_pressed() -> void:
	_start_listen(ABILITY_SLOT)


func _on_supply_bind_pressed(slot_index: int) -> void:
	if _listening_slot == slot_index:
		_cancel_listen()
		return
	_start_listen(slot_index)


func _start_listen(slot: int) -> void:
	_listening_slot = slot
	for btn in _all_bind_buttons:
		btn.disabled = true
		btn.focus_mode = Control.FOCUS_NONE
	var active_btn := _button_for_slot(slot)
	active_btn.text = "PRESS A KEY..."
	# use modulate for the amber tint since disabled overrides style overrides
	active_btn.modulate = Color(1.4, 1.1, 0.4, 1.0)
	active_btn.release_focus()


func _button_for_slot(slot: int) -> Button:
	if slot == FIRE_SLOT:
		return fire_button
	if slot == ABILITY_SLOT:
		return ability_button
	return supply_buttons[slot]


func _try_apply_binding(event: InputEvent) -> void:
	var active_btn := _button_for_slot(_listening_slot)

	if event is InputEventKey:
		var unicode: int = event.unicode
		# reject a-z
		if unicode >= BLOCKED_UNICODE_START and unicode <= BLOCKED_UNICODE_END:
			_flash_error(active_btn, "NOT ALLOWED (A-Z)")
			return

		var keycode: int = event.physical_keycode
		var ok := false
		if _listening_slot == FIRE_SLOT:
			ok = SettingsState.set_fire_key(keycode)
		elif _listening_slot == ABILITY_SLOT:
			ok = SettingsState.set_ability_key(keycode)
		else:
			ok = SettingsState.set_supply_key(_listening_slot, keycode)

		if not ok:
			_flash_error(active_btn, "ALREADY USED")
			return

	elif event is InputEventMouseButton:
		# mouse buttons only valid for fire and the ability, supply needs keyboard
		var mouse_ok := false
		if _listening_slot == FIRE_SLOT:
			mouse_ok = SettingsState.set_fire_mouse_button(event.button_index)
		elif _listening_slot == ABILITY_SLOT:
			mouse_ok = SettingsState.set_ability_mouse_button(event.button_index)
		else:
			_flash_error(active_btn, "KEYS ONLY")
			return
		if not mouse_ok:
			_flash_error(active_btn, "ALREADY USED")
			return

	_cancel_listen()
	_refresh_bind_buttons()


func _flash_error(btn: Button, msg: String) -> void:
	btn.text = msg
	btn.modulate = Color(1.5, 0.5, 0.5, 1.0)
	await get_tree().create_timer(0.8).timeout
	if _listening_slot != -1:
		btn.text = "PRESS A KEY..."
		btn.modulate = Color(1.4, 1.1, 0.4, 1.0)


func _cancel_listen() -> void:
	for btn in _all_bind_buttons:
		btn.disabled = false
		btn.focus_mode = Control.FOCUS_ALL
		btn.modulate = Color(1, 1, 1, 1)
	_listening_slot = -1
	_refresh_bind_buttons()


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


func _on_reduce_flashing_toggle_toggled(toggled_on: bool) -> void:
	SettingsState.set_reduce_flashing(toggled_on)


func _on_window_mode_option_item_selected(index: int) -> void:
	SettingsState.set_fullscreen(index == 1)
	resolution_option.disabled = SettingsState.fullscreen


func _on_resolution_option_item_selected(index: int) -> void:
	SettingsState.set_resolution_index(index)


func _on_back_button_pressed() -> void:
	if _listening_slot != -1:
		_cancel_listen()
		return
	closed.emit()
