extends GutTest

const WaveCounterScene := preload("res://scenes/ui/wave_counter.tscn")
const WaveCounterScript := preload("res://scripts/ui/wave_counter.gd")


func test_wave_text_shows_current_and_total() -> void:
	assert_eq(WaveCounterScript.wave_text(2, 3), "WAVE 2 / 3")


func test_wave_text_without_a_total_shows_just_the_wave() -> void:
	assert_eq(WaveCounterScript.wave_text(1, 0), "WAVE 1")


func test_counter_is_hidden_until_the_first_wave_starts() -> void:
	var manager := ZombieManager.new()
	add_child_autofree(manager)
	var counter = WaveCounterScene.instantiate()
	add_child_autofree(counter)
	counter.setup(manager)
	assert_false(counter.panel.visible)

	manager._max_display_wave_number = 3
	manager.wave_started.emit(1, false)

	assert_true(counter.panel.visible)
	assert_eq(counter.label.text, "WAVE 1 / 3")
