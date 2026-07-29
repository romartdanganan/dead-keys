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
