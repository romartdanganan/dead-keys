class_name SupplySlotRow
extends Button

const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")

signal slot_pressed(slot_index: int)

const COLOUR_SELECTED := Color(0.35, 0.85, 0.35)
const COLOUR_UNSELECTED := Color(0.55, 0.55, 0.55)

@export var slot_index: int = 0

@onready var number_label: Label = $Content/NumberLabel
@onready var icon_rect: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/NameLabel

var card_style: StyleBoxFlat


func _ready() -> void:
	# duplicate so each slot can have its own border colour
	card_style = get_theme_stylebox("normal").duplicate()
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, card_style)

	pressed.connect(_on_pressed)
	refresh(false)


func refresh(is_selected: bool) -> void:
	number_label.text = "[SLOT %d]" % (slot_index + 1)

	var supply_id := SupplyState.get_slot(slot_index)
	if supply_id.is_empty():
		name_label.text = "CLICK TO SELECT"
		icon_rect.modulate.a = 0.3
	else:
		var supply := SupplyCatalog.get_supply(supply_id)
		name_label.text = supply.get("display_name", "")
		icon_rect.modulate.a = 1.0

	card_style.border_color = COLOUR_SELECTED if is_selected else COLOUR_UNSELECTED


func _on_pressed() -> void:
	slot_pressed.emit(slot_index)
