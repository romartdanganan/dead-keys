extends CanvasLayer

# one line hint banner above the typing panel, queues messages so they never overlap

const FADE_SECONDS: float = 0.3
const HOLD_SECONDS: float = 3.5

@onready var panel: PanelContainer = $Root/Panel
@onready var label: Label = $Root/Panel/Margin/Label

var _queue: Array[String] = []
var _showing: bool = false


func _ready() -> void:
	panel.modulate.a = 0.0


func show_callout(text: String) -> void:
	_queue.append(text)
	if not _showing:
		_show_next()


func is_showing() -> bool:
	return _showing


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	label.text = _queue.pop_front()
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, FADE_SECONDS)
	tween.tween_interval(HOLD_SECONDS)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_SECONDS)
	tween.finished.connect(_show_next)
