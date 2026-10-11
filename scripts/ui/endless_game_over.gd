extends CanvasLayer

# endless game over screen, the layout lives in endless_game_over.tscn
# this script fills in the results and plays the entrance animation

signal play_again_requested
signal main_menu_requested

const SCORE_COUNT_SECONDS: float = 0.9

@onready var subtitle_label: Label = %SubtitleLabel
@onready var score_label: Label = %ScoreLabel
@onready var best_label: Label = %BestLabel
@onready var best_badge: PanelContainer = %NewBestBadge
@onready var play_again_button: Button = %PlayAgainButton
@onready var main_menu_button: Button = %MainMenuButton
# stat cards by name, e.g. stat_values["KILLS"].text
@onready var stat_values: Dictionary = {
	"KILLS": %KillsValue,
	"ACCURACY": %AccuracyValue,
	"WPM": %WpmValue,
}
@onready var _backdrop: ColorRect = $Backdrop
@onready var _card: PanelContainer = %Card


func _ready() -> void:
	# the pop in scales from the middle, and the card's size is only known after layout
	_card.resized.connect(func() -> void: _card.pivot_offset = _card.size / 2.0)


# accuracy and wpm are -1 when the player never typed, shown as a dash instead of a fake 100%
func show_results(results: Dictionary) -> void:
	subtitle_label.text = "You held out until round %d" % results["round"]
	stat_values["KILLS"].text = str(results["kills"])
	stat_values["ACCURACY"].text = "-" if results["accuracy"] < 0 else "%d%%" % results["accuracy"]
	stat_values["WPM"].text = "-" if results["wpm"] < 0 else str(results["wpm"])
	best_label.text = str(results["best"])
	best_badge.visible = results["new_best"]
	score_label.text = str(results["score"])
	_play_entrance(results["score"])


# card pops in and the score counts up, purely visual so the final text is already set
func _play_entrance(final_score: int) -> void:
	_backdrop.modulate.a = 0.0
	_card.modulate.a = 0.0
	_card.scale = Vector2.ONE * 0.92
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_backdrop, "modulate:a", 1.0, 0.3)
	tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: int) -> void: score_label.text = str(value), 0, final_score, SCORE_COUNT_SECONDS).set_delay(0.2)


func _on_play_again_button_pressed() -> void:
	play_again_requested.emit()


func _on_main_menu_button_pressed() -> void:
	main_menu_requested.emit()
