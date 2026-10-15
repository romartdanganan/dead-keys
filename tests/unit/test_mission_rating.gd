extends GutTest

# mission medals, bonus gold, perfect accuracy bonus and best medal saving

const MissionRating := preload("res://scripts/missions/mission_rating.gd")
const ProgressionBackup := preload("res://tests/helpers/progression_backup.gd")

var _backup := ProgressionBackup.new()
var typing: TypingController
var rating: MissionRating


func before_each() -> void:
	_backup.backup()
	ProgressionManager.best_medals = {}
	typing = TypingController.new()
	typing.word_list_path = ""
	add_child_autofree(typing)
	rating = MissionRating.new()
	rating.setup(typing)


func after_each() -> void:
	_backup.restore()


func _type(correct: int, wrong: int) -> void:
	for i in correct:
		typing.correct_stroke.emit()
	for i in wrong:
		typing.typing_mistake.emit()


func test_accuracy_counts_correct_and_wrong_keystrokes() -> void:
	_type(9, 1)
	assert_almost_eq(rating.get_accuracy(), 0.9, 0.001)


func test_accuracy_is_full_before_any_typing() -> void:
	assert_eq(rating.get_accuracy(), 1.0)


func test_gold_needs_accuracy_wall_health_and_no_lives_lost() -> void:
	assert_eq(MissionRating.grade(0.95, 0.6, 0), MissionRating.GOLD)


func test_losing_a_life_blocks_gold() -> void:
	assert_eq(MissionRating.grade(1.0, 1.0, 1), MissionRating.SILVER)


func test_low_wall_health_drops_gold_to_silver() -> void:
	assert_eq(MissionRating.grade(1.0, 0.59, 0), MissionRating.SILVER)


func test_silver_needs_accuracy_and_some_wall_health() -> void:
	assert_eq(MissionRating.grade(0.85, 0.3, 0), MissionRating.SILVER)
	assert_eq(MissionRating.grade(0.84, 1.0, 0), MissionRating.BRONZE)
	assert_eq(MissionRating.grade(1.0, 0.29, 0), MissionRating.BRONZE)


func test_medal_bonus_matches_gdd() -> void:
	assert_eq(MissionRating.get_medal_bonus(MissionRating.BRONZE), 25)
	assert_eq(MissionRating.get_medal_bonus(MissionRating.SILVER), 50)
	assert_eq(MissionRating.get_medal_bonus(MissionRating.GOLD), 100)
	assert_eq(MissionRating.get_medal_bonus(MissionRating.NONE), 0)


func test_lives_lost_feed_into_the_medal() -> void:
	_type(20, 0)
	rating.record_life_lost()
	assert_eq(rating.get_medal(1.0), MissionRating.SILVER)


func test_perfect_typing_pays_ten_percent_of_the_reward() -> void:
	_type(20, 0)
	assert_eq(rating.get_perfect_accuracy_bonus(100), 10)


func test_one_mistake_loses_the_perfect_accuracy_bonus() -> void:
	_type(20, 1)
	assert_eq(rating.get_perfect_accuracy_bonus(100), 0)


func test_no_typing_gets_no_perfect_accuracy_bonus() -> void:
	assert_eq(rating.get_perfect_accuracy_bonus(100), 0)


func test_unplayed_mission_has_no_medal() -> void:
	assert_eq(ProgressionManager.get_best_medal(1), MissionRating.NONE)


func test_better_medal_replaces_the_saved_one() -> void:
	ProgressionManager.set_best_medal(1, MissionRating.BRONZE)
	assert_true(ProgressionManager.set_best_medal(1, MissionRating.GOLD))
	assert_eq(ProgressionManager.get_best_medal(1), MissionRating.GOLD)


func test_worse_medal_never_overwrites_a_better_one() -> void:
	ProgressionManager.set_best_medal(2, MissionRating.GOLD)
	assert_false(ProgressionManager.set_best_medal(2, MissionRating.BRONZE))
	assert_eq(ProgressionManager.get_best_medal(2), MissionRating.GOLD)


func test_best_medals_survive_save_and_reload() -> void:
	ProgressionManager.set_best_medal(1, MissionRating.SILVER)
	ProgressionManager.save_progression()

	ProgressionManager.best_medals = {}
	ProgressionManager.load_progression()

	assert_eq(ProgressionManager.get_best_medal(1), MissionRating.SILVER)


func test_every_medal_has_a_sprite_and_none_does_not() -> void:
	for medal in [MissionRating.BRONZE, MissionRating.SILVER, MissionRating.GOLD]:
		assert_not_null(MissionRating.get_medal_texture(medal), medal)
	assert_null(MissionRating.get_medal_texture(MissionRating.NONE))


# the medal sprite is a node in the Mission Complete scene, sized up with sharp pixels
func test_mission_complete_screen_has_a_sharp_medal_icon() -> void:
	var overlay = load("res://scenes/ui/mission_success_overlay.tscn").instantiate()
	add_child_autofree(overlay)
	assert_true(overlay.medal_icon is TextureRect)
	assert_eq(overlay.medal_icon.custom_minimum_size, Vector2(96, 96))
	assert_eq(overlay.medal_icon.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


# home base hides its medal icon until a mission with a medal is picked
func test_home_base_medal_icon_starts_hidden() -> void:
	var state: SceneState = load("res://scenes/ui/home_base.tscn").get_state()
	var found := false
	for node_index in state.get_node_count():
		if state.get_node_name(node_index) != "BestMedalIcon":
			continue
		found = true
		for property_index in state.get_node_property_count(node_index):
			if state.get_node_property_name(node_index, property_index) == "visible":
				assert_false(state.get_node_property_value(node_index, property_index))
	assert_true(found, "BestMedalIcon should be a node in home_base.tscn")


# types a word with an even gap between keys, starting at start_seconds
func _type_word(length: int, start_seconds: float, gap_seconds: float) -> void:
	for i in length:
		rating.record_correct_stroke(int((start_seconds + i * gap_seconds) * 1000000.0))
	rating.end_word()


func test_wpm_is_zero_before_any_typing() -> void:
	assert_eq(rating.get_words_per_minute(), 0)


# five keys 0.2 s apart is one key every 0.2 s, which is 300 keys or 60 words a minute
func test_wpm_counts_the_gaps_between_keys_in_a_word() -> void:
	_type_word(5, 0.0, 0.2)
	assert_eq(rating.timed_strokes, 4)
	assert_almost_eq(rating.typing_seconds, 0.8, 0.001)
	assert_eq(rating.get_words_per_minute(), 60)


# the wait between words, like a round break, never counts as typing time
func test_wpm_ignores_time_between_words() -> void:
	_type_word(5, 0.0, 0.2)
	_type_word(5, 30.0, 0.2)
	assert_almost_eq(rating.typing_seconds, 1.6, 0.001)
	assert_eq(rating.get_words_per_minute(), 60)


# stopping mid word, like opening the pause menu, is skipped instead of dragging wpm down
func test_wpm_skips_a_long_pause_inside_a_word() -> void:
	rating.record_correct_stroke(0)
	rating.record_correct_stroke(200000)
	rating.record_correct_stroke(10200000)
	rating.record_correct_stroke(10400000)
	rating.end_word()
	assert_eq(rating.timed_strokes, 2)
	assert_almost_eq(rating.typing_seconds, 0.4, 0.001)


# a finished word or a lost target ends the word, so the next key starts a fresh clock
func test_typing_controller_signals_end_the_word() -> void:
	rating.record_correct_stroke(0)
	typing.word_completed.emit("cat", 1)
	rating.record_correct_stroke(500000)
	assert_eq(rating.timed_strokes, 0)
	typing.target_unregistered.emit()
	rating.record_correct_stroke(900000)
	assert_eq(rating.timed_strokes, 0)
