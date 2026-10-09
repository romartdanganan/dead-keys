extends Node

# low wall health warning and ability ready glow on the HUD panels

const LOW_WALL_FRACTION: float = 0.25
const PULSE_SPEED: float = 6.0
const WALL_WARNING_COLOUR: Color = Color(1.0, 0.4, 0.4)
# above 1.0 so the panel glows brighter than normal rather than just tinting
const ABILITY_READY_COLOUR: Color = Color(1.35, 1.2, 0.55)

var _wall_bar: ProgressBar
var _wall_panel: Control
var _ability_panel: Control
var _ability_ready: bool = false
var _time: float = 0.0


func setup(wall_bar: ProgressBar, wall_panel: Control, ability_panel: Control) -> void:
	_wall_bar = wall_bar
	_wall_panel = wall_panel
	_ability_panel = ability_panel
	_ability_ready = AbilityState.is_charged
	AbilityState.charged_changed.connect(_on_charged_changed)


static func is_wall_low(value: float, max_value: float) -> bool:
	return max_value > 0.0 and value / max_value <= LOW_WALL_FRACTION


# pulses between normal and the warning colour, or holds the warning colour steady
static func warning_colour(target: Color, time: float, reduce_flashing: bool) -> Color:
	if reduce_flashing:
		return target
	var pulse := (sin(time * PULSE_SPEED) + 1.0) / 2.0
	return Color.WHITE.lerp(target, pulse)


func _process(delta: float) -> void:
	_time += delta
	var reduce := SettingsState.reduce_flashing
	if _wall_panel != null:
		var low := is_wall_low(_wall_bar.value, _wall_bar.max_value)
		_wall_panel.modulate = warning_colour(WALL_WARNING_COLOUR, _time, reduce) if low else Color.WHITE
	if _ability_panel != null:
		_ability_panel.modulate = warning_colour(ABILITY_READY_COLOUR, _time, reduce) if _ability_ready else Color.WHITE


func _on_charged_changed(is_charged: bool) -> void:
	_ability_ready = is_charged
