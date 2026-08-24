class_name SupplySlotRow
extends Button

const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")

signal slot_pressed(slot_index: int)

const COLOUR_SELECTED := Color(0.35, 0.85, 0.35)
const COLOUR_UNSELECTED := Color(0.55, 0.55, 0.55)
const COLOUR_SELL_HOVER := Color(0.85, 0.35, 0.35)

@export var slot_index: int = 0

@onready var number_label: Label = $Content/NumberLabel
@onready var icon_rect: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/NameLabel
@onready var hint_label: Label = $Content/HintLabel

var card_style: StyleBoxFlat
var is_hovering: bool = false
var is_selected_cache: bool = false


func _ready() -> void:
	# duplicate so each slot can have its own border colour
	card_style = get_theme_stylebox("normal").duplicate()
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, card_style)

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	refresh(false)


func refresh(is_selected: bool) -> void:
	is_selected_cache = is_selected
	number_label.text = "[SLOT %d]" % (slot_index + 1)

	var supply_id := SupplyState.get_slot(slot_index)

	if supply_id.is_empty():
		icon_rect.modulate.a = 0.3
		name_label.text = "CLICK TO SELECT"
		hint_label.text = ""
		card_style.border_color = COLOUR_SELECTED if is_selected else COLOUR_UNSELECTED
		return

	icon_rect.modulate.a = 1.0
	var supply := SupplyCatalog.get_supply(supply_id)

	# hovering an occupied slot previews the sell price instead of the
	# equipped supply, clicking then sells and refunds it
	if is_hovering:
		name_label.text = "SELL FOR"
		hint_label.text = "%d GOLD?" % supply.get("cost", 0)
		card_style.border_color = COLOUR_SELL_HOVER
	else:
		name_label.text = supply.get("display_name", "")
		hint_label.text = "(HOVER TO SELL)"
		card_style.border_color = COLOUR_SELECTED if is_selected else COLOUR_UNSELECTED


func _on_mouse_entered() -> void:
	is_hovering = true
	refresh(is_selected_cache)


func _on_mouse_exited() -> void:
	is_hovering = false
	refresh(is_selected_cache)


func _on_pressed() -> void:
	slot_pressed.emit(slot_index)
