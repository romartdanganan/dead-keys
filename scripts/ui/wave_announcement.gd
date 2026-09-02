class_name WaveAnnouncement
extends CanvasLayer

@onready var wave_label: Label = $Root/WaveLabel

const FADE_IN_SECONDS: float = 0.3
const HOLD_SECONDS: float = 1.2
const FADE_OUT_SECONDS: float = 0.4
const SCALE_START: Vector2 = Vector2(0.9, 0.9)
const SCALE_END: Vector2 = Vector2(1.0, 1.0)

var _active_tween: Tween


func show_wave(wave_number: int) -> void:
	wave_label.text = "WAVE %d" % wave_number
	_play_announcement()


# lets a mission scene show a custom line instead of the default "WAVE N"
# text, e.g. a boss intro or "FINAL WAVE" without needing a second scene
func show_text(announcement_text: String) -> void:
	wave_label.text = announcement_text
	_play_announcement()


func _play_announcement() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()

	wave_label.modulate.a = 0.0
	wave_label.scale = SCALE_START

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(wave_label, "modulate:a", 1.0, FADE_IN_SECONDS)
	_active_tween.tween_property(wave_label, "scale", SCALE_END, FADE_IN_SECONDS).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_active_tween.chain().tween_interval(HOLD_SECONDS)
	_active_tween.chain().tween_property(wave_label, "modulate:a", 0.0, FADE_OUT_SECONDS)
