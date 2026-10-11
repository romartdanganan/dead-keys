extends CanvasLayer

# endless game over screen: one big score, the round reached, then stat cards and two buttons
# built in code and kept separate from the mission fail overlay so that one stays as it is

signal play_again_requested
signal main_menu_requested

const BACKDROP_COLOUR := Color(0.05, 0.04, 0.06, 0.82)
const CARD_COLOUR := Color(0.13, 0.12, 0.15)
const STAT_COLOUR := Color(0.19, 0.18, 0.22)
const ACCENT_COLOUR := Color(0.78, 0.22, 0.22)
const SCORE_COLOUR := Color(1.0, 0.82, 0.3)
const MUTED_COLOUR := Color(0.65, 0.63, 0.7)
const SCORE_COUNT_SECONDS: float = 0.9

var subtitle_label: Label
var score_label: Label
var best_badge: PanelContainer
# stat cards by name, e.g. stat_values["KILLS"].text
var stat_values: Dictionary = {}
var play_again_button: Button
var main_menu_button: Button
var _backdrop: ColorRect
var _card: PanelContainer


func _init() -> void:
	# the mission pauses the tree behind this screen
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP_COLOUR
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_backdrop)

	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(centre)

	_card = PanelContainer.new()
	_card.custom_minimum_size = Vector2(880, 0)
	_card.add_theme_stylebox_override("panel", _box(CARD_COLOUR, 10, ACCENT_COLOUR, 4, 48))
	# the pop in scales from the middle, and the size is only known after layout
	_card.resized.connect(func() -> void: _card.pivot_offset = _card.size / 2.0)
	centre.add_child(_card)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 26)
	_card.add_child(layout)

	var header := _stack(4)
	header.add_child(_label("OVERRUN", 44, ACCENT_COLOUR))
	subtitle_label = _label("", 30, MUTED_COLOUR)
	header.add_child(subtitle_label)
	layout.add_child(header)

	var score_block := _stack(0)
	score_block.add_child(_label("SCORE", 26, MUTED_COLOUR))
	score_label = _label("0", 120, SCORE_COLOUR)
	score_block.add_child(score_label)
	best_badge = PanelContainer.new()
	best_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	best_badge.add_theme_stylebox_override("panel", _box(SCORE_COLOUR, 6, SCORE_COLOUR, 0, 10))
	best_badge.add_child(_label("NEW BEST!", 30, CARD_COLOUR))
	best_badge.visible = false
	score_block.add_child(best_badge)
	layout.add_child(score_block)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, 2)
	divider.color = STAT_COLOUR
	layout.add_child(divider)

	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 18)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	for title in ["KILLS", "ACCURACY", "WPM", "BEST"]:
		stats.add_child(_stat_card(title))
	layout.add_child(stats)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	play_again_button = _button("PLAY AGAIN", ACCENT_COLOUR)
	play_again_button.pressed.connect(func() -> void: play_again_requested.emit())
	main_menu_button = _button("MAIN MENU", STAT_COLOUR)
	main_menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	buttons.add_child(play_again_button)
	buttons.add_child(main_menu_button)
	layout.add_child(buttons)


# accuracy and wpm are -1 when the player never typed, shown as a dash instead of a fake 100%
func show_results(results: Dictionary) -> void:
	subtitle_label.text = "You held out until round %d" % results["round"]
	stat_values["KILLS"].text = str(results["kills"])
	stat_values["ACCURACY"].text = "-" if results["accuracy"] < 0 else "%d%%" % results["accuracy"]
	stat_values["WPM"].text = "-" if results["wpm"] < 0 else str(results["wpm"])
	stat_values["BEST"].text = str(results["best"])
	best_badge.visible = results["new_best"]
	score_label.text = str(results["score"])
	_play_entrance(results["score"])


# card pops in and the score counts up, purely visual so the final text is already set
func _play_entrance(final_score: int) -> void:
	if not is_inside_tree():
		return
	_backdrop.modulate.a = 0.0
	_card.modulate.a = 0.0
	_card.scale = Vector2.ONE * 0.92
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_backdrop, "modulate:a", 1.0, 0.3)
	tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: int) -> void: score_label.text = str(value), 0, final_score, SCORE_COUNT_SECONDS).set_delay(0.2)


func _stat_card(title: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 0)
	card.add_theme_stylebox_override("panel", _box(STAT_COLOUR, 8, STAT_COLOUR, 0, 16))
	var stack := _stack(2)
	stack.add_child(_label(title, 22, MUTED_COLOUR))
	var value := _label("-", 54, Color.WHITE)
	stack.add_child(value)
	card.add_child(stack)
	stat_values[title] = value
	return card


func _button(text: String, colour: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(280, 68)
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _box(colour, 8, colour, 0, 12))
	button.add_theme_stylebox_override("hover", _box(colour.lightened(0.15), 8, Color.WHITE, 2, 12))
	button.add_theme_stylebox_override("pressed", _box(colour.darkened(0.2), 8, colour, 0, 12))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), 8, Color.WHITE, 2, 12))
	return button


func _label(text: String, size: int, colour: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	return label


func _stack(separation: int) -> VBoxContainer:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", separation)
	return stack


func _box(colour: Color, radius: int, border_colour: Color, border: int, padding: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(radius)
	box.border_color = border_colour
	box.set_border_width_all(border)
	box.set_content_margin_all(padding)
	return box
