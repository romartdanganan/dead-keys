extends Node2D
class_name BarrierRing

@export_range(90.0, 120.0, 1.0) var radius: float = 105.0:
	set(value):
		radius = clampf(value, 90.0, 120.0)
		queue_redraw()

@export var ring_color: Color = Color(1.0, 0.85, 0.15, 1.0)
@export var fill_color: Color = Color(1.0, 0.85, 0.15, 0.08)

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 128, ring_color, 4.0, true)
