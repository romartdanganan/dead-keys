class_name AbilityRow
extends Button

const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")

signal select_pressed(ability_id: String)

const COLOUR_LOCKED := Color(0.35, 0.35, 0.35)
const COLOUR_UNEQUIPPED := Color(0.55, 0.55, 0.55)
const COLOUR_EQUIPPED := Color(0.35, 0.85, 0.35)

@export var ability_id: String = ""

@onready var icon_rect: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/NameLabel
@onready var status_label: Label = $Content/StatusLabel

var card_style: StyleBoxFlat


func _ready() -> void:
	# duplicate so each card can have its own border colour without
	# touching the shared theme
	card_style = get_theme_stylebox("normal").duplicate()
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, card_style)

	pressed.connect(_on_pressed)
	refresh()


func refresh() -> void:
	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty():
		push_warning("AbilityRow has unknown ability_id: " + ability_id)
		return

	name_label.text = ability.display_name
	tooltip_text = ability.description

	var equipped: bool = AbilityState.equipped_ability_id == ability_id

	if not ability.implemented:
		status_label.text = "SOON"
		card_style.border_color = COLOUR_LOCKED
		status_label.add_theme_color_override("font_color", COLOUR_LOCKED)
		self_modulate.a = 0.55
	elif equipped:
		status_label.text = "EQUIPPED"
		card_style.border_color = COLOUR_EQUIPPED
		status_label.add_theme_color_override("font_color", COLOUR_EQUIPPED)
		self_modulate.a = 1.0
	else:
		status_label.text = ""
		card_style.border_color = COLOUR_UNEQUIPPED
		self_modulate.a = 1.0


func _on_pressed() -> void:
	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty() or not ability.implemented:
		return
	select_pressed.emit(ability_id)
