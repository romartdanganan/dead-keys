extends Control

const AbilityRow := preload("res://scripts/ui/ability_row.gd")

@onready var rows_container: GridContainer = $MainMargin/MainLayout/GridArea/RowsContainer

var ability_rows: Array[AbilityRow] = []


func _ready() -> void:
	# collect the 8 ability cards laid out in the tscn and wire their clicks
	for child in rows_container.get_children():
		if child is AbilityRow:
			ability_rows.append(child)
			child.select_pressed.connect(_on_row_select_pressed)


func _on_row_select_pressed(ability_id: String) -> void:
	AbilityState.equip(ability_id)
	for row in ability_rows:
		row.refresh()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")
