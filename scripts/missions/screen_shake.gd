extends Camera2D

# mission camera that shakes on big moments, skipped when reduce screen shake is on
# trauma builds up from hits and fades out, the shake is trauma squared so small hits stay subtle

const MAX_OFFSET: float = 10.0
const TRAUMA_DECAY: float = 1.6
# background gets this much extra on every side so a shake never shows its edge
const BACKGROUND_BLEED: float = 24.0

var trauma: float = 0.0
var _zoom_tween: Tween


func _ready() -> void:
	position = get_viewport_rect().size / 2.0
	make_current()


func add_trauma(amount: float) -> void:
	if SettingsState.reduce_screen_shake:
		return
	trauma = minf(trauma + amount, 1.0)


# quick zoom in that eases back, used for the boss entrance
func zoom_pulse(amount: float, seconds: float) -> void:
	if SettingsState.reduce_screen_shake:
		return
	_kill_zoom_tween()
	zoom = Vector2.ONE * (1.0 + amount)
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "zoom", Vector2.ONE, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# glides the camera onto a point and zooms in, in real time so slow motion does not drag it out
func focus_on(point: Vector2, zoom_level: float, seconds: float) -> Tween:
	_kill_zoom_tween()
	var half_view := get_viewport_rect().size / (2.0 * zoom_level)
	var screen := get_viewport_rect().size
	# kept inside the screen so the zoomed view never shows past the background
	var target := Vector2(clampf(point.x, half_view.x, screen.x - half_view.x), clampf(point.y, half_view.y, screen.y - half_view.y))
	_zoom_tween = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_zoom_tween.tween_property(self, "position", target, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_zoom_tween.tween_property(self, "zoom", Vector2.ONE * zoom_level, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	return _zoom_tween


# glides back to the normal full screen view
func reset_focus(seconds: float) -> Tween:
	_kill_zoom_tween()
	_zoom_tween = create_tween().set_ignore_time_scale(true).set_parallel(true)
	_zoom_tween.tween_property(self, "position", get_viewport_rect().size / 2.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_zoom_tween.tween_property(self, "zoom", Vector2.ONE, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _zoom_tween


func _kill_zoom_tween() -> void:
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()


# grows a full screen background so camera movement never reveals the edge
static func bleed_background(background: Control) -> void:
	background.position -= Vector2.ONE * BACKGROUND_BLEED
	background.size += Vector2.ONE * BACKGROUND_BLEED * 2.0


func _process(delta: float) -> void:
	if trauma <= 0.0:
		offset = Vector2.ZERO
		return
	trauma = maxf(trauma - TRAUMA_DECAY * delta, 0.0)
	var strength := trauma * trauma * MAX_OFFSET
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
