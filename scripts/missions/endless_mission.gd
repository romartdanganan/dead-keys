extends "res://scripts/missions/mission_1.gd"

# endless survival: rounds keep coming until the last life is lost, then the score is saved
# reuses the whole mission, only the round loop, HUD text and game over screen change

const EndlessWaves := preload("res://scripts/missions/endless_waves.gd")
const EndlessScores := preload("res://scripts/missions/endless_scores.gd")
const ENDLESS_GAME_OVER := preload("res://scripts/ui/endless_game_over.gd")
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"

# short breather between rounds, plus a small wall repair as a reward
const ROUND_BREAK_SECONDS: float = 3.0
const ROUND_WALL_REPAIR: float = 0.25

var round_number: int = 1
var rounds_cleared: int = 0
var _seconds_played: float = 0.0
var game_over_screen: CanvasLayer = null


func _init() -> void:
	# 0 is not a real mission, so no medal is saved and Next Mission stays off
	mission_number = 0


func _ready() -> void:
	super()
	_update_endless_label()


func _process(delta: float) -> void:
	super(delta)
	_seconds_played += delta


func _build_mission_config() -> MissionConfigDef:
	return EndlessWaves.build_round(round_number)


# alt tabbing on the game over screen must not open the pause menu over it
func _open_pause_menu() -> void:
	if game_over_screen != null:
		return
	super()


# a boss is just a tough round here, killing it never ends the run
func _setup_boss_fight() -> void:
	super()
	boss_fight.ends_mission = false


# the round number lives in the mission panel instead of a wave counter
func _setup_wave_counter() -> void:
	pass


func _on_wave_started(_wave_number: int, _is_final_wave: bool) -> void:
	if EndlessWaves.is_boss_round(round_number):
		wave_announcement.show_text("ROUND %d: BOSS" % round_number)
	else:
		wave_announcement.show_text("ROUND %d" % round_number)


func _on_zombie_died(dead_zombie: Zombie) -> void:
	super(dead_zombie)
	_update_endless_label()


# no medal or gold, the next round starts after a short break
func _on_all_waves_cleared() -> void:
	rounds_cleared += 1
	round_number += 1
	wall_health = minf(wall_health + WALL_MAX_HEALTH * ROUND_WALL_REPAIR, WALL_MAX_HEALTH)
	_update_wall_hud()
	_update_endless_label()
	wave_announcement.show_text("ROUND CLEAR")
	# the manager marks itself stopped right after this signal, so restarting waits for the break
	await get_tree().create_timer(ROUND_BREAK_SECONDS, false).timeout
	if not is_inside_tree() or game_over_screen != null:
		return
	zombie_manager.mission_config = _build_mission_config()
	zombie_manager.start_mission()


func get_score() -> int:
	return EndlessScores.compute_score(kill_count, rounds_cleared)


# words per minute counts five keystrokes as one word, the usual typing test rule
func get_words_per_minute() -> int:
	if _seconds_played <= 0.0:
		return 0
	return roundi((mission_rating.correct_strokes / 5.0) / (_seconds_played / 60.0))


# its own game over screen with the score up front, the mission fail overlay stays for missions
func _display_mission_fail_overlay() -> void:
	if zombie_manager:
		zombie_manager.stop_mission()
	Audio.clear_music()
	Audio.play("game_over")
	var score := get_score()
	var previous_best := EndlessScores.best_score()
	EndlessScores.submit(score, round_number)
	game_over_screen = ENDLESS_GAME_OVER.new()
	add_child(game_over_screen)
	game_over_screen.show_results(build_results(score, previous_best))
	game_over_screen.play_again_requested.connect(_on_play_again_requested)
	game_over_screen.main_menu_requested.connect(_on_main_menu_requested)
	get_tree().paused = true


# typing stats are -1 until the player has typed, so the screen never shows a fake 100%
func build_results(score: int, previous_best: int) -> Dictionary:
	var typed := mission_rating.correct_strokes > 0
	return {
		"score": score,
		"round": round_number,
		"kills": kill_count,
		"accuracy": floori(mission_rating.get_accuracy() * 100) if typed else -1,
		"wpm": get_words_per_minute() if typed else -1,
		"best": maxi(score, previous_best),
		"new_best": score > previous_best,
	}


func _on_play_again_requested() -> void:
	get_tree().paused = false
	Audio.clear_sounds()
	Audio.play("play_music")
	get_tree().reload_current_scene()


# endless starts from the main menu, so it goes back there instead of Home Base
func _on_main_menu_requested() -> void:
	get_tree().paused = false
	SupplyState.clear_loadout()
	Audio.clear_music()
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _update_endless_label() -> void:
	$HUD/HUDRoot/MissionPanel/MissionMargin/MissionNameLabel.text = "ENDLESS: ROUND %d\nSCORE %d" % [round_number, get_score()]
