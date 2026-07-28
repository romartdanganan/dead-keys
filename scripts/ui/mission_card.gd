class_name MissionCard
extends Button

@export var mission_id: int = 1
@export var mission_name: String = "THE SUBURBS"
@export_multiline var mission_description: String = ""
@export var mission_image: Texture2D
@export var best_medal: String = "NONE"
@export var locked: bool = false

@onready var mission_image_rect: TextureRect = (
	$CardMargin/CardContent/MissionImage
)
@onready var mission_name_label: Label = (
	$CardMargin/CardContent/MissionNameLabel
)
@onready var lock_overlay: ColorRect = $LockOverlay


func _ready() -> void:
	_update_card()


func _update_card() -> void:
	mission_name_label.text = "%d. %s" % [mission_id, mission_name]

	if mission_image != null:
		mission_image_rect.texture = mission_image

	lock_overlay.visible = locked
	disabled = locked
