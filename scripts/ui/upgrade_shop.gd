extends Control

# preload rather than rely on the class_name global (which needs an editor
# filesystem rescan to register on a fresh checkout / new machine)
const UpgradeRow := preload("res://scripts/ui/upgrade_row.gd")

@onready var gold_label: Label = $MainMargin/MainLayout/TopBar/GoldPanel/GoldMargin/GoldContent/GoldLabel
@onready var rows_container: VBoxContainer = (
	$MainMargin/MainLayout/RowsScroll/RowsContainer
)

var upgrade_rows: Array[UpgradeRow] = []


func _ready() -> void:
	UpgradeState.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(UpgradeState.get_gold())

	for child in rows_container.get_children():
		if child is UpgradeRow:
			upgrade_rows.append(child)
			child.buy_pressed.connect(_on_row_buy_pressed)


func _on_gold_changed(new_gold: int) -> void:
	gold_label.text = "GOLD: %d" % new_gold


func _on_row_buy_pressed(track_id: String) -> void:
	UpgradeState.purchase_upgrade(track_id)
	_refresh_all_rows()


func _refresh_all_rows() -> void:
	for row in upgrade_rows:
		row.refresh()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/home_base.tscn")
