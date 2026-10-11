extends RefCounted

# end of mission medal (GDD 2.6) from typing accuracy, wall health left and lives lost,
# accessibility options never lower it so slower typists are not punished for using them

const NONE := "NONE"
const BRONZE := "BRONZE"
const SILVER := "SILVER"
const GOLD := "GOLD"
const MEDAL_RANK: Dictionary = {NONE: 0, BRONZE: 1, SILVER: 2, GOLD: 3}
const MEDAL_BONUS: Dictionary = {BRONZE: 25, SILVER: 50, GOLD: 100}
# 32x32 pixel art medals, NONE has no sprite
const MEDAL_TEXTURES: Dictionary = {
	BRONZE: preload("res://assets/ui/medal_bronze.png"),
	SILVER: preload("res://assets/ui/medal_silver.png"),
	GOLD: preload("res://assets/ui/medal_gold.png"),
}

# first pass thresholds, tune after playtest #3
const GOLD_ACCURACY: float = 0.95
const GOLD_WALL_FRACTION: float = 0.6
const SILVER_ACCURACY: float = 0.85
const SILVER_WALL_FRACTION: float = 0.3
# a mission with no typing mistakes pays this share of its base reward on top
const PERFECT_ACCURACY_SHARE: float = 0.1
# a longer gap between two keys of a word is not typing, e.g. the pause menu or stopping to shoot
const MAX_KEY_GAP_SECONDS: float = 1.5

var correct_strokes: int = 0
var mistakes: int = 0
var lives_lost: int = 0
# wpm only uses the gaps between keys inside a word, never the wait between words
var typing_seconds: float = 0.0
var timed_strokes: int = 0
var _last_stroke_usec: int = -1


# listens to every keystroke the typing controller judges
func setup(typing_controller: TypingController) -> void:
	typing_controller.correct_stroke.connect(_on_correct_stroke)
	typing_controller.typing_mistake.connect(_on_typing_mistake)
	# a word ends when it is finished or its target is gone, the next key starts a new one
	typing_controller.word_completed.connect(func(_word: String, _reward: int) -> void: end_word())
	typing_controller.supply_word_completed.connect(func(_crate: Node, _word: String) -> void: end_word())
	typing_controller.target_unregistered.connect(end_word)


# called by the mission each time the wall breaks and a life is spent
func record_life_lost() -> void:
	lives_lost += 1


# share of keystrokes that were correct, 1.0 before anything is typed
func get_accuracy() -> float:
	var total := correct_strokes + mistakes
	if total == 0:
		return 1.0
	return float(correct_strokes) / total


# five keystrokes count as one word, the usual typing test rule, 0 before any timed typing
func get_words_per_minute() -> int:
	if typing_seconds <= 0.0:
		return 0
	return roundi((timed_strokes / 5.0) / (typing_seconds / 60.0))


# the first key of a word only starts its clock, each later key adds the gap since the last one
func record_correct_stroke(now_usec: int) -> void:
	correct_strokes += 1
	if _last_stroke_usec >= 0:
		var gap := (now_usec - _last_stroke_usec) / 1000000.0
		if gap <= MAX_KEY_GAP_SECONDS:
			typing_seconds += gap
			timed_strokes += 1
	_last_stroke_usec = now_usec


func end_word() -> void:
	_last_stroke_usec = -1


# medal for this run, wall_fraction is wall health left divided by max health
func get_medal(wall_fraction: float) -> String:
	return grade(get_accuracy(), wall_fraction, lives_lost)


# needs at least one keystroke so an empty run never counts as perfect
func get_perfect_accuracy_bonus(base_reward: int) -> int:
	if correct_strokes == 0 or mistakes > 0:
		return 0
	return roundi(base_reward * PERFECT_ACCURACY_SHARE)


# gold needs high accuracy, a healthy wall and no lives lost, silver allows a lost life
static func grade(accuracy: float, wall_fraction: float, lives_lost_count: int) -> String:
	if accuracy >= GOLD_ACCURACY and wall_fraction >= GOLD_WALL_FRACTION and lives_lost_count == 0:
		return GOLD
	if accuracy >= SILVER_ACCURACY and wall_fraction >= SILVER_WALL_FRACTION:
		return SILVER
	return BRONZE


# bonus gold for a medal, 0 for NONE
static func get_medal_bonus(medal: String) -> int:
	return MEDAL_BONUS.get(medal, 0)


# sprite for a medal, null for NONE
static func get_medal_texture(medal: String) -> Texture2D:
	return MEDAL_TEXTURES.get(medal)


# used so a worse run never replaces a saved better medal
static func is_better(new_medal: String, old_medal: String) -> bool:
	return MEDAL_RANK.get(new_medal, 0) > MEDAL_RANK.get(old_medal, 0)


func _on_correct_stroke() -> void:
	record_correct_stroke(Time.get_ticks_usec())


func _on_typing_mistake() -> void:
	mistakes += 1
