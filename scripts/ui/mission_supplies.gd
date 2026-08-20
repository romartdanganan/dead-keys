extends Control

const SupplySlotRow := preload("res://scripts/ui/supply_slot_row.gd")
const SupplyCardRow := preload("res://scripts/ui/supply_card_row.gd")

@onready var gold_label: Label = $MainMargin/MainLayout/TopBar/GoldPanel/GoldMargin/GoldContent/GoldLabel
@onready var slots_container: VBoxContainer = $MainMargin/MainLayout/HubContent/SlotsPanel/SlotsMargin/SlotsContent/SlotsList
@onready var cards_container: GridContainer = $MainMargin/MainLayout/HubContent/CardsArea/CardsContainer

var slot_rows: Array[SupplySlotRow] = []
var card_rows: Array[SupplyCardRow] = []

# which slot a BUY press will purchase into
var selected_slot: int = -1


func _ready() -> void:
	UpgradeState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(UpgradeState.get_gold())

	for child in slots_container.get_children():
		if child is SupplySlotRow:
			slot_rows.append(child)
			child.slot_pressed.connect(_on_slot_pressed)

	for child in cards_container.get_children():
		if child is SupplyCardRow:
			card_rows.append(child)
			child.buy_pressed.connect(_on_buy_pressed)

	selected_slot = SupplyState.first_empty_slot()
	if selected_slot == -1:
		selected_slot = 0

	_refresh_slots()


func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "GOLD: %d" % new_gold


func _on_slot_pressed(slot_index: int) -> void:
	selected_slot = slot_index
	_refresh_slots()


func _on_buy_pressed(supply_id: String) -> void:
	var target_slot := selected_slot
	if target_slot == -1:
		target_slot = SupplyState.first_empty_slot()
		if target_slot == -1:
			return

	if SupplyState.purchase_into_slot(target_slot, supply_id):
		# jump to the next empty slot so repeat buys don't overwrite
		var next_empty := SupplyState.first_empty_slot()
		selected_slot = next_empty if next_empty != -1 else target_slot

	_refresh_slots()
	_refresh_cards()


func _refresh_slots() -> void:
	for row in slot_rows:
		row.refresh(row.slot_index == selected_slot)


func _refresh_cards() -> void:
	for row in card_rows:
		row.refresh()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")
