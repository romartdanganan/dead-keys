extends GutTest

# endless game over screen: stat cards, the new best badge and the two buttons

const ENDLESS_GAME_OVER_SCENE := preload("res://scenes/ui/endless_game_over.tscn")

var screen: CanvasLayer


func before_each() -> void:
	screen = ENDLESS_GAME_OVER_SCENE.instantiate()
	add_child_autofree(screen)


func _results(overrides: Dictionary = {}) -> Dictionary:
	var results := {"score": 640, "round": 7, "kills": 34, "accuracy": 92, "wpm": 48, "best": 900, "new_best": false}
	results.merge(overrides, true)
	return results


func test_shows_the_score_round_and_stats() -> void:
	screen.show_results(_results())
	assert_eq(screen.score_label.text, "640")
	assert_eq(screen.subtitle_label.text, "You held out until round 7")
	assert_eq(screen.stat_values["KILLS"].text, "34")
	assert_eq(screen.stat_values["ACCURACY"].text, "92%")
	assert_eq(screen.stat_values["WPM"].text, "48")
	assert_eq(screen.best_label.text, "900")


# best sits beside the score, so the cards only hold this run's stats
func test_best_is_beside_the_score_not_a_stat_card() -> void:
	assert_false(screen.stat_values.has("BEST"))
	assert_eq(screen.best_label.get_parent().get_parent(), screen.score_label.get_parent().get_parent())


func test_no_typing_shows_dashes_not_a_fake_score() -> void:
	screen.show_results(_results({"accuracy": -1, "wpm": -1}))
	assert_eq(screen.stat_values["ACCURACY"].text, "-")
	assert_eq(screen.stat_values["WPM"].text, "-")


func test_new_best_badge_only_shows_for_a_new_best() -> void:
	screen.show_results(_results())
	assert_false(screen.best_badge.visible)
	screen.show_results(_results({"score": 1200, "best": 1200, "new_best": true}))
	assert_true(screen.best_badge.visible)


func test_buttons_ask_the_mission_to_act() -> void:
	watch_signals(screen)
	screen.play_again_button.pressed.emit()
	screen.main_menu_button.pressed.emit()
	assert_signal_emitted(screen, "play_again_requested")
	assert_signal_emitted(screen, "main_menu_requested")


# the mission pauses the tree, so the screen has to keep running
func test_screen_still_works_while_paused() -> void:
	assert_eq(screen.process_mode, Node.PROCESS_MODE_ALWAYS)
