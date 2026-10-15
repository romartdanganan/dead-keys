class_name SupplyCrate
extends Node2D

# a dropped supply crate (#29, GDD §2.2.4): claimed by typing its word
# within EXPIRY_SECONDS, otherwise it despawns unclaimed

const SupplyTextures := preload("res://scripts/resources/supply_textures.gd")

signal claimed(crate: SupplyCrate)
signal expired(crate: SupplyCrate)

@export var supply_type: String = ""

const EXPIRY_SECONDS: float = 8.0

@onready var expiry_timer: Timer = $ExpiryTimer
@onready var time_bar: ProgressBar = $TimeBar
@onready var crate_sprite: Sprite2D = $CrateSprite2D


func _ready() -> void:
	# longer crate timer accessibility setting stretches the claim window
	var expiry_seconds := EXPIRY_SECONDS * SettingsState.get_crate_timer_multiplier()
	expiry_timer.wait_time = expiry_seconds
	expiry_timer.one_shot = true
	expiry_timer.timeout.connect(_on_expiry_timeout)
	expiry_timer.start()

	time_bar.max_value = expiry_seconds
	time_bar.value = expiry_seconds

	# keeps icon.svg placeholder if supply_type has no drawn crate yet
	var texture := SupplyTextures.get_texture(supply_type)
	if texture != null:
		crate_sprite.texture = texture


func _process(_delta: float) -> void:
	time_bar.value = expiry_timer.time_left


func claim() -> void:
	expiry_timer.stop()
	claimed.emit(self)
	queue_free()


func _on_expiry_timeout() -> void:
	expired.emit(self)
	queue_free()
