extends Control




@onready var selected_mission_image: TextureRect = (
	$MainMargin/MainLayout/HubContent/MissionDetailsPanel
	/MissionDetailsMargin/MissionDetails/SelectedMissionImage
)

@onready var mission_title_label: Label = (
	$MainMargin/MainLayout/HubContent/MissionDetailsPanel
	/MissionDetailsMargin/MissionDetails/MissionTitleLabel
)

@onready var mission_description_label: Label = (
	$MainMargin/MainLayout/HubContent/MissionDetailsPanel
	/MissionDetailsMargin/MissionDetails/MissionDescriptionLabel
)

@onready var best_medal_label: Label = (
	$MainMargin/MainLayout/HubContent/MissionDetailsPanel
	/MissionDetailsMargin/MissionDetails/BestMedalLabel
)

@onready var mission_1_card: MissionCard = (
	$MainMargin/MainLayout/HubContent/MissionArea
	/MissionTable/MissionGrid/Mission1Card
)


func _ready() -> void:
	_show_mission_details(mission_1_card)
	ProgressionManager.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(ProgressionManager.get_gold())
	
	
#Gold Debug text
func _on_gold_changed(new_gold: int) -> void:
	$MainMargin/MainLayout/TopBar/GoldPanel/GoldMargin/GoldContent/GoldLabel.text = "Gold: %d" % new_gold

#Gold Debug Keys
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		ProgressionManager.add_gold(100)

	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		var success := ProgressionManager.spend_gold(10000)
		print("Spend success: ", success)
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_U:
		var success1 := ProgressionManager.purchase_upgrade("fire_rate")
		print("Purchase success: ", success1, " | Level: ", ProgressionManager.get_upgrade_level("fire_rate"))
		
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		ProgressionManager.save_progression()
		print("Saved.")
		
func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_mission_1_card_pressed() -> void:
	_show_mission_details(mission_1_card)


func _show_mission_details(card: MissionCard) -> void:
	mission_title_label.text = "%d. %s" % [
		card.mission_id,
		card.mission_name
	]

	mission_description_label.text = card.mission_description
	best_medal_label.text = card.best_medal

	if card.mission_image != null:
		selected_mission_image.texture = card.mission_image


func _on_launch_mission_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/missions/gameplay_prototype.tscn")


func _on_upgrades_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/upgrade_shop.tscn")


func _on_ability_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ability_select.tscn")
