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

const SETTINGS_MENU_SCENE := preload("res://scenes/ui/settings_menu.tscn")
var settings_menu: Node = null


func _ready() -> void:
	# only swap to menu music if mission music is playing (returning from a
	# mission). sub-screens like Upgrades navigate back here too, and they
	# should not restart the already-playing menu music mid-song.
	if Audio.is_playing("play_music"):
		Audio.clear_music()
		Audio.play("main_music")
	else:
		Audio.play("main_music")
	_show_mission_details(mission_1_card)
	ProgressionManager.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(ProgressionManager.get_gold())


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if get_viewport().gui_get_hovered_control() is Button:
				Audio.play("click")
			else:
				Audio.play("thud")

func _on_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_settings_button_pressed() -> void:
	if settings_menu != null:
		return
	settings_menu = SETTINGS_MENU_SCENE.instantiate()
	add_child(settings_menu)
	settings_menu.closed.connect(_on_settings_menu_closed)


func _on_settings_menu_closed() -> void:
	settings_menu.queue_free()
	settings_menu = null


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
	Audio.clear_music()
	Audio.play("play_music")
	get_tree().change_scene_to_file("res://scenes/missions/mission_1.tscn")


func _on_upgrades_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/upgrade_shop.tscn")


func _on_supplies_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/mission_supplies.tscn")


func _on_ability_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/ability_select.tscn")
	
	
func _on_gold_changed(new_gold: int) -> void:
	$MainMargin/MainLayout/TopBar/GoldPanel/GoldMargin/GoldContent/GoldLabel.text = "Gold: %d" % new_gold

#Progression Manger Debug Keys
func _unhandled_input(event: InputEvent) -> void:
	# debug keys only work when running from the editor, never in exported builds
	if not OS.is_debug_build():
		return
	#Add gold
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		ProgressionManager.add_gold(50)
	#Check if spending gold
	if event is InputEventKey and event.pressed and event.keycode == KEY_H:
		var success := ProgressionManager.spend_gold(10000)
		print("Spend success: ", success)
	#Manual save check
	if event is InputEventKey and event.pressed and event.keycode == KEY_S:
		ProgressionManager.save_progression()
		print("Saved.")
	#Reset save check
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		ProgressionManager.reset_progression()
		# debug reset also brings back every tutorial callout
		TutorialState.reset()
		print("Progression reset.")
