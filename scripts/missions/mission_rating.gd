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

var correct_strokes: int = 0
var mistakes: int = 0
var lives_lost: int = 0


# listens to every keystroke the typing controller judges
func setup(typing_controller: TypingController) -> void:
	typing_controller.correct_stroke.connect(_on_correct_stroke)
	typing_controller.typing_mistake.connect(_on_typing_mistake)


# called by the mission each time the wall breaks and a life is spent
func record_life_lost() -> void:
	lives_lost += 1


# share of keystrokes that were correct, 1.0 before anything is typed
func get_accuracy() -> float:
	var total := correct_strokes + mistakes
	if total == 0:
		return 1.0
	return float(correct_strokes) / total


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


# square medal sprite scaled up with sharp pixels, hidden when there is no medal
static func make_medal_icon(medal: String, icon_size: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = get_medal_texture(medal)
	icon.visible = icon.texture != null
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


# used so a worse run never replaces a saved better medal
static func is_better(new_medal: String, old_medal: String) -> bool:
	return MEDAL_RANK.get(new_medal, 0) > MEDAL_RANK.get(old_medal, 0)


func _on_correct_stroke() -> void:
	correct_strokes += 1


func _on_typing_mistake() -> void:
	mistakes += 1
