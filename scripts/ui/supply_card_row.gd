class_name SupplyCardRow
extends PanelContainer

const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")

signal buy_pressed(supply_id: String)

@export var supply_id: String = ""

@onready var name_label: Label = $Margin/Content/NameLabel
@onready var cost_label: Label = $Margin/Content/CostLabel
@onready var buy_button: Button = $Margin/Content/BuyButton


func _ready() -> void:
	buy_button.pressed.connect(_on_buy_pressed)
	refresh()


# repaints the buy button, disabled when gold is insufficient or the
# currently selected loadout slot is already occupied
func refresh(selected_slot_occupied: bool = false) -> void:
	var supply := SupplyCatalog.get_supply(supply_id)
	if supply.is_empty():
		push_warning("SupplyCardRow has unknown supply_id: " + supply_id)
		return

	name_label.text = supply.display_name
	tooltip_text = supply.description
	cost_label.text = "%d GOLD" % supply.cost

	if selected_slot_occupied:
		buy_button.text = "SLOT FULL"
		buy_button.disabled = true
	else:
		buy_button.text = "BUY"
		buy_button.disabled = not UpgradeState.can_afford(supply.cost)


func _on_buy_pressed() -> void:
	buy_pressed.emit(supply_id)
