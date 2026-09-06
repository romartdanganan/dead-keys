extends Control

const AbilityRow := preload("res://scripts/ui/ability_row.gd")

@onready var rows_container: GridContainer = $MainMargin/MainLayout/GridArea/RowsContainer
@onready var gold_label: Label = $MainMargin/MainLayout/TopBar/GoldPanel/GoldMargin/GoldContent/GoldLabel

var ability_rows: Array[AbilityRow] = []


func _ready() -> void:
	UpgradeState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(UpgradeState.get_gold())

	# collect the 8 ability cards laid out in the tscn and wire their clicks
	for child in rows_container.get_children():
		if child is AbilityRow:
			ability_rows.append(child)
			child.select_pressed.connect(_on_row_select_pressed)


func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "GOLD: %d" % new_gold


func _on_row_select_pressed(ability_id: String) -> void:
	AbilityState.equip(ability_id)
	for row in ability_rows:
		row.refresh()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")
