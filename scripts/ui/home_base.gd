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

@onready var mission_grid: GridContainer = (
	$MainMargin/MainLayout/HubContent/MissionArea
	/MissionTable/MissionGrid
)

const MissionCatalog := preload("res://scripts/resources/mission_catalog.gd")

var mission_cards: Array[MissionCard] = []
var selected_card: MissionCard = null

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
	_setup_mission_cards()
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


# unlocks every built mission the player has reached, then selects the latest
func _setup_mission_cards() -> void:
	for child in mission_grid.get_children():
		if child is MissionCard:
			mission_cards.append(child)
			var unlocked: bool = child.mission_id <= ProgressionManager.highest_unlocked and MissionCatalog.has_mission(child.mission_id)
			child.locked = not unlocked
			child._update_card()
			child.pressed.connect(_show_mission_details.bind(child))

	var latest_card: MissionCard = mission_cards[0]
	for card in mission_cards:
		if not card.locked and card.mission_id > latest_card.mission_id:
			latest_card = card
	_show_mission_details(latest_card)


func _show_mission_details(card: MissionCard) -> void:
	selected_card = card
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
	# launches whichever unlocked mission card is selected
	get_tree().change_scene_to_file(MissionCatalog.get_scene_path(selected_card.mission_id))


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
		print("Progression reset.")
