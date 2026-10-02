extends GutTest

# every mission word list must load and only hold words the player can type

const WORD_LIST_DIR := "res://resources/word_lists/"
const MIN_WORDS := 10


func _load_words(file_name: String) -> Array:
	var file := FileAccess.open(WORD_LIST_DIR + file_name, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("words"):
		return []
	return parsed["words"]


func _list_files() -> PackedStringArray:
	var files := PackedStringArray()
	for file_name in DirAccess.get_files_at(WORD_LIST_DIR):
		if file_name.ends_with(".json"):
			files.append(file_name)
	return files


func test_every_built_mission_has_a_word_list() -> void:
	assert_true("mission_1_words_PLACEHOLDER.json" in _list_files())
	assert_true("mission_2_words_PLACEHOLDER.json" in _list_files())


func test_every_word_list_parses_with_enough_words() -> void:
	for file_name in _list_files():
		var words := _load_words(file_name)
		assert_gte(words.size(), MIN_WORDS, file_name + " has too few words")


# typing only accepts a to z, so anything else could never be completed
func test_every_word_is_lowercase_letters_only() -> void:
	var regex := RegEx.create_from_string("^[a-z]+$")
	for file_name in _list_files():
		for word in _load_words(file_name):
			assert_not_null(regex.search(str(word)), "%s has an untypeable word: %s" % [file_name, word])


func test_no_word_list_has_duplicates() -> void:
	for file_name in _list_files():
		var seen := {}
		for word in _load_words(file_name):
			assert_false(seen.has(word), "%s repeats %s" % [file_name, word])
			seen[word] = true
