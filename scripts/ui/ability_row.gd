class_name AbilityRow
extends Button

const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")

signal select_pressed(ability_id: String)

const COLOUR_LOCKED := Color(0.35, 0.35, 0.35)
const COLOUR_UNEQUIPPED := Color(0.55, 0.55, 0.55)
const COLOUR_EQUIPPED := Color(0.35, 0.85, 0.35)
const COLOUR_HOVER := Color(0.85, 0.75, 0.3)

const BORDER_WIDTH_NORMAL := 2
const BORDER_WIDTH_HOVER := 4

@export var ability_id: String = ""

@onready var icon_rect: TextureRect = $Content/Icon
@onready var name_label: Label = $Content/NameLabel
@onready var status_label: Label = $Content/StatusLabel

var card_style: StyleBoxFlat
var is_hovering: bool = false


func _ready() -> void:
	# duplicate so each card can have its own border colour without
	# touching the shared theme
	card_style = get_theme_stylebox("normal").duplicate()
	for state in ["normal", "hover", "pressed", "focus"]:
		add_theme_stylebox_override(state, card_style)

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	# other cards buying an ability changes gold, which can flip this card
	# between affordable and not, so it needs to react even when it isn't
	# the one being interacted with
	UpgradeState.gold_changed.connect(_on_gold_changed)
	refresh()


func refresh() -> void:
	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty():
		push_warning("AbilityRow has unknown ability_id: " + ability_id)
		return

	name_label.text = ability.display_name
	tooltip_text = ability.description

	var equipped: bool = AbilityState.equipped_ability_id == ability_id
	var owned: bool = UpgradeState.is_ability_owned(ability_id)

	if not ability.implemented:
		status_label.text = "SOON"
		card_style.border_color = COLOUR_LOCKED
		card_style.set_border_width_all(BORDER_WIDTH_NORMAL)
		status_label.add_theme_color_override("font_color", COLOUR_LOCKED)
		self_modulate.a = 0.55
		return

	if not owned:
		var cost: int = ability.get("cost", 0)
		var affordable := UpgradeState.can_afford(cost)
		status_label.text = "BUY: %d GOLD" % cost
		var locked_colour := COLOUR_HOVER if (is_hovering and affordable) else COLOUR_LOCKED
		card_style.border_color = locked_colour
		card_style.set_border_width_all(BORDER_WIDTH_HOVER if (is_hovering and affordable) else BORDER_WIDTH_NORMAL)
		status_label.add_theme_color_override("font_color", locked_colour)
		self_modulate.a = 1.0 if affordable else 0.6
		return

	if equipped:
		status_label.text = "EQUIPPED"
		card_style.border_color = COLOUR_EQUIPPED
		card_style.set_border_width_all(BORDER_WIDTH_NORMAL)
		status_label.add_theme_color_override("font_color", COLOUR_EQUIPPED)
		self_modulate.a = 1.0
	elif is_hovering:
		# owned but not equipped, pointer is over it, tell the player it's clickable
		status_label.text = "CLICK TO EQUIP"
		card_style.border_color = COLOUR_HOVER
		card_style.set_border_width_all(BORDER_WIDTH_HOVER)
		status_label.add_theme_color_override("font_color", COLOUR_HOVER)
		self_modulate.a = 1.0
	else:
		status_label.text = ""
		card_style.border_color = COLOUR_UNEQUIPPED
		card_style.set_border_width_all(BORDER_WIDTH_NORMAL)
		self_modulate.a = 1.0


func _on_mouse_entered() -> void:
	is_hovering = true
	refresh()


func _on_mouse_exited() -> void:
	is_hovering = false
	refresh()


func _on_gold_changed(_new_gold: int) -> void:
	refresh()


func _on_pressed() -> void:
	var ability := AbilityCatalog.get_ability(ability_id)
	if ability.is_empty() or not ability.implemented:
		return

	# first click on a locked card buys it, a second click (now owned) equips
	# it, kept as two separate steps to match the buy/select pattern already
	# used by the Mission Supplies shop rather than inventing a new one
	if not UpgradeState.is_ability_owned(ability_id):
		UpgradeState.purchase_ability(ability_id)
		refresh()
		return

	select_pressed.emit(ability_id)
