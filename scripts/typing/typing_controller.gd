class_name TypingController
extends Node

signal typing_mistake
signal correct_stroke
signal word_completed(word: String, ammunition_reward: int)
signal supply_word_completed(crate: Node, word: String)
signal target_unregistered()

# keeps the old single-target prototype scene working temporarily
@export var word_label: RichTextLabel

const LETTERS := "abcdefghijklmnopqrstuvwxyz"

# placeholder word list source. this is a temporary stand-in for #43's
# real per-mission word list system, kept here only so Mission 1 is
# playable in the meantime. safe to repoint or replace this loading logic
# entirely once the real system lands
@export var word_list_path: String = "res://resources/word_lists/mission_1_words_PLACEHOLDER.json"

# fallback used if word_list_path is empty or fails to load
var test_words: Array[String] = [
	"code",
	"walker",
	"undead",
	"keyboard",
	"survivor",
	"defence",
	"suburb",
	"barricade",
	"outbreak",
	"zombie",
	"unbelievable",
	"brain"
]

# each entry stores the walker, its label, its word and completion state
var active_targets: Array[Dictionary] = []

# shared prefix currently typed by the player
var typed_prefix: String = ""


func _ready() -> void:
	_load_word_list()

	# temporary compatibility for the existing single-target prototype
	if is_instance_valid(word_label):
		register_target(word_label, word_label)


# loads test_words from word_list_path if set and valid, otherwise keeps
# the hardcoded fallback above. see the comment on word_list_path
func _load_word_list() -> void:
	if word_list_path.is_empty():
		return

	if not FileAccess.file_exists(word_list_path):
		push_warning("TypingController: word_list_path not found, using fallback words: " + word_list_path)
		return

	var file := FileAccess.open(word_list_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("words"):
		push_warning("TypingController: word_list_path malformed, using fallback words: " + word_list_path)
		return

	var loaded_words: Array[String] = []
	for entry in parsed["words"]:
		if typeof(entry) == TYPE_STRING:
			loaded_words.append(entry)

	if loaded_words.is_empty():
		push_warning("TypingController: word_list_path had no usable words, using fallback words: " + word_list_path)
		return

	test_words = loaded_words


# deal with the last input, catch the keypress and print out the unicode
func _unhandled_input(event: InputEvent) -> void:
	# do nothing if no zombies are currently active
	if active_targets.is_empty():
		return

	if not (event is InputEventKey): # key pressed or release
		return

	if not event.pressed or event.echo: # ignore spam keys and pressed
		return

	if event.unicode == 0: # allow arrows/espace keys 
		return

	var typed_character := char(event.unicode).to_lower()

	if not LETTERS.contains(typed_character): # reject numbers and etc 
		return

	get_viewport().set_input_as_handled() # letters only work for typing
	check_letter(typed_character)


func register_target(target: Node, label: RichTextLabel, kind: String = "zombie") -> void:
	if not is_instance_valid(target) or not is_instance_valid(label):
		return

	# avoid registering the same walker more than once
	for target_data in active_targets:
		if target_data["target"] == target:
			return

	var new_word := _choose_unique_word()

	if new_word.is_empty():
		push_warning("TypingController: no unused words are available")
		return

	active_targets.append({
		"target": target,
		"label": label,
		"word": new_word,
		"kind": kind,
	})

	_update_all_labels()


func unregister_target(target: Node) -> void:
	# iterate backwards to safely remove targets without skipping indices
	for index in range(active_targets.size() - 1, -1, -1):
		if active_targets[index]["target"] == target:
			active_targets.remove_at(index)

	typed_prefix = ""
	target_unregistered.emit()
	_update_all_labels()


func check_letter(typed_character: String) -> void:
	_remove_invalid_targets()

	if active_targets.is_empty():
		return

	var proposed_prefix := typed_prefix + typed_character
	var matching_targets: Array[Dictionary] = []

	# find all active targets that match the newly extended prefix
	for target_data in active_targets:

		var word: String = target_data["word"]

		if word.to_lower().begins_with(proposed_prefix):
			matching_targets.append(target_data)

	# trigger mistake if no active zombie word starts with this prefix
	if matching_targets.is_empty():
		print("mistake - no active word matches: ", proposed_prefix)
		typing_mistake.emit()
		return

	typed_prefix = proposed_prefix
	correct_stroke.emit()
	_update_all_labels()

	print("correct - current prefix: ", typed_prefix)

	# check if any matching word has been fully typed
	for target_data in matching_targets:
		var word: String = target_data["word"]

		if word.to_lower() == typed_prefix:
			_complete_target(target_data)
			return


func _complete_target(target_data: Dictionary) -> void:
	var completed_word: String = target_data["word"]
	var kind: String = target_data.get("kind", "zombie")

	print("WORD COMPLETE: ", completed_word)

	typed_prefix = ""

	# supply crates are claimed once, not reassigned a new word like zombies
	if kind == "supply":
		var crate_target: Node = target_data["target"]
		unregister_target(crate_target)
		supply_word_completed.emit(crate_target, completed_word)
		return

	# TODO: scale ammo reward by word length per GDD
	word_completed.emit(completed_word, 1)

	# assign the living zombie a new word, avoiding its previous one
	var replacement_word := _choose_unique_word_for_target(
		target_data,
		completed_word
	)

	# fallback to old word if pool is temporarily exhausted
	if replacement_word.is_empty():
		push_warning("TypingController: no replacement word is available")
		target_data["word"] = completed_word
	else:
		target_data["word"] = replacement_word

	_update_all_labels()

func _update_all_labels() -> void:
	_remove_invalid_targets()

	for target_data in active_targets:
		var label: RichTextLabel = target_data["label"]
		var word: String = target_data["word"]

		# prevents a crash after the target is freed and its WordLabel are freed
		if not is_instance_valid(label):
			continue

		if typed_prefix.is_empty():
			label.text = word
			continue

		# highlight the matching typed prefix on valid labels
		if word.to_lower().begins_with(typed_prefix):
			var highlighted_length := typed_prefix.length()
			var highlighted_text := word.substr(0, highlighted_length)
			var remaining_text := word.substr(highlighted_length)

			label.text = "[color=#5aa9e6]%s[/color]%s" % [
				highlighted_text,
				remaining_text
			]
		else:
			# words that no longer match lose their highlight
			label.text = word


# picks a random word from the pool that isn't currently assigned to an active zombie
func _choose_unique_word() -> String:
	var available_words: Array[String] = []

	for candidate_word in test_words:
		if not _is_word_active(candidate_word):
			available_words.append(candidate_word)

	if available_words.is_empty():
		return ""

	return available_words.pick_random()


# checks if a word is currently assigned to an active uncompleted target
func _is_word_active(word: String) -> bool:
	for target_data in active_targets:
		var active_word: String = target_data["word"]

		if active_word.to_lower() == word.to_lower():
			return true

	return false


# removes freed or invalid target nodes from the active array to prevent null references
func _remove_invalid_targets() -> void:
	for index in range(active_targets.size() - 1, -1, -1):
		var target_data: Dictionary = active_targets[index]

		# keep these untyped so freed references can be checked safely
		var target = target_data.get("target")
		var label = target_data.get("label")

		if not is_instance_valid(target) or not is_instance_valid(label):
			active_targets.remove_at(index)


# finds an available word that no other active zombie is using
# and avoids re-assigning the same word the zombie just had
func _choose_unique_word_for_target(target_to_replace: Dictionary, previous_word: String) -> String:
	var available_words: Array[String] = []

	for candidate_word in test_words:
		# skip the word this zombie just finished
		if candidate_word.to_lower() == previous_word.to_lower():
			continue

		var used_by_another_target := false

		# ensure no other zombie on screen has this word
		for target_data in active_targets:
			if target_data == target_to_replace:
				continue

			if target_data["word"].to_lower() == candidate_word.to_lower():
				used_by_another_target = true
				break

		if not used_by_another_target:
			available_words.append(candidate_word)

	if available_words.is_empty():
		return ""

	return available_words.pick_random()
