class_name UpgradeRow
extends PanelContainer

# preload rather than rely on the class_name global (which needs an editor
# filesystem rescan to register on a fresh checkout / new machine)
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")

# one row in the Upgrade Shop representing a single track from UpgradeCatalog.
# set track_id in the Inspector per instance (see upgrade_shop.tscn).

signal buy_pressed(track_id: String)

@export var track_id: String = ""

@onready var name_label: Label = $Margin/Content/NameLabel
@onready var level_label: Label = $Margin/Content/LevelLabel
@onready var value_label: Label = $Margin/Content/ValueLabel
@onready var cost_label: Label = $Margin/Content/CostLabel
@onready var buy_button: Button = $Margin/Content/BuyButton


func _ready() -> void:
	refresh()


# repaints this row from current UpgradeState — call after any purchase
func refresh() -> void:
	var track := UpgradeCatalog.get_track(track_id)
	if track.is_empty():
		push_warning("UpgradeRow has unknown track_id: " + track_id)
		return

	var current_level := UpgradeState.get_upgrade_level(track_id)
	var max_level := UpgradeCatalog.get_max_level(track_id)
	var current_value: Variant = UpgradeCatalog.get_level_value(track_id, current_level)

	name_label.text = track.display_name
	level_label.text = "LEVEL %d / %d" % [current_level, max_level]
	value_label.text = "CURRENT: %s%s" % [str(current_value), track.unit_suffix]

	if current_level >= max_level:
		cost_label.text = "MAXED"
		buy_button.text = "MAXED"
		buy_button.disabled = true
	else:
		var cost: int = UpgradeCatalog.get_cost_for_next_level(track_id, current_level)
		cost_label.text = "COST: %d GOLD" % cost
		buy_button.text = "UPGRADE"
		buy_button.disabled = not UpgradeState.can_afford(cost)


func _on_buy_button_pressed() -> void:
	buy_pressed.emit(track_id)
