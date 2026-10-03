extends Node2D

# animated ring showing an ability's area of effect, frees itself when done

const DURATION: float = 0.4
const SPARK_COUNT: int = 10

var radius: float = 100.0
var colour: Color = Color(1.0, 0.55, 0.15)
var show_sparks: bool = false
var _elapsed: float = 0.0


func _ready() -> void:
	# draw above zombies so the blast is never hidden behind them
	z_index = 10


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := clampf(_elapsed / DURATION, 0.0, 1.0)
	var grow := 1.0 - pow(1.0 - t, 3.0)
	var alpha := 1.0 - t

	# filled blast area growing out to the real radius
	draw_circle(Vector2.ZERO, radius * grow, Color(colour, 0.3 * alpha))
	# bright core flash that shrinks away quickly
	draw_circle(Vector2.ZERO, radius * 0.45 * (1.0 - t), Color(1.0, 0.95, 0.7, alpha))
	# outer ring lands exactly on the effect radius
	draw_arc(Vector2.ZERO, radius * grow, 0.0, TAU, 64, Color(colour, alpha), 4.0)

	if show_sparks:
		for i in SPARK_COUNT:
			var dir := Vector2.RIGHT.rotated(TAU * i / SPARK_COUNT)
			draw_line(dir * radius * 0.4 * grow, dir * radius * 0.9 * grow, Color(1.0, 0.85, 0.4, alpha), 3.0)
