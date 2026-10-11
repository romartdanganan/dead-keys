extends GutTest

# word lists (#43): shared theme files mixed into per-mission pools
#   themes/*.json          {"theme": "suburb", "words": [...]}
#   missions_words/*.json  {"themes": [...], "word_count": 20, "allowed_buckets": [1, 2, 3]}
# any .json left directly in word_lists/ is an old flat list
# (mission 3 until it moves to themes)
const WORD_LIST_DIR := "res://resources/word_lists/"
const THEMES_DIR := "res://resources/word_lists/themes/"
const MISSIONS_DIR := "res://resources/word_lists/missions_words/"
const MIN_WORDS := 10


func before_each() -> void:
	# the loader keeps a static cache, so clear for every test
	WordListLoader.clear_cache()
	
func _read_json(path: String) -> Variant:
	var file:= FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
	

func _list_json(dir: String) -> PackedStringArray:
	var files := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		if file_name.ends_with(".json"):
			files.append(file_name)
	return files
	
func _all_word_files() -> PackedStringArray:
		var paths := PackedStringArray()
		for file_name in _list_json(THEMES_DIR):
			paths.append(THEMES_DIR + file_name)
		for file_name in _list_json(WORD_LIST_DIR):
			paths.append(WORD_LIST_DIR + file_name)
		return paths
		
func _load_words(path: String) -> Array:
	var parsed = _read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("words"):
		return []
	return parsed["words"]


func test_every_built_mission_has_a_word_list() -> void:
	var missions := _list_json(MISSIONS_DIR)
	for number in range(1, 7):
		assert_true("mission%d_words.json" % number in missions, "missing word list for mission %d" % number)

# the tank only uses long words, so the boss mission needs plenty of them
func test_mission_3_has_enough_long_words_for_the_boss() -> void:
	var data = _read_json(MISSIONS_DIR + "mission3_words.json")
	var long_words := {}
	for theme_name in data["themes"]:
		for word in _load_words(THEMES_DIR + str(theme_name) + ".json"):
			if String(word).length() >= 9:
				long_words[word] = true   # dictionary, so a word in 2 themes only counts once
	assert_gte(long_words.size(), 15)


func test_every_word_file_parses_with_enough_words() -> void:
	for path in _all_word_files():
		assert_gte(_load_words(path).size(), MIN_WORDS, path + " has too few words")



# typing only accepts a to z, so anything else could never be completed
func test_every_word_is_lowercase_letters_only() -> void:
	var regex := RegEx.create_from_string("^[a-z]+$")
	for path in _all_word_files():
		for word in _load_words(path):
			assert_not_null(regex.search(str(word)), "%s has an untypeable word: %s" % [path, word])


func test_no_word_list_has_duplicates() -> void:
	for path in _all_word_files():
		var seen := {}
		for word in _load_words(path):
			assert_false(seen.has(word), "%s repeats %s" % [path, word])
			seen[word] = true


func test_every_mission_file_is_vaild() -> void:
	for file_name in _list_json(MISSIONS_DIR):
		var data = _read_json(MISSIONS_DIR + file_name)
		assert_eq(typeof(data), TYPE_DICTIONARY, file_name + "did not parse")
		if typeof(data) != TYPE_DICTIONARY:
			continue
		assert_false(data.get("themes",[]).is_empty(), file_name + " lists no themes")
		assert_gt(int(data.get("word_count", 0)),0, file_name + " need a word_count over 0")
		# buckets match GDD §2.2.1 ammo tiers, so only 1 to 4 exist
		for bucket in data.get("allowed_buckets", []):
			assert_between(int(bucket),1, 4, file_name + " has a bucket outside 1-4")
			
# a typo in a theme name doesn't crash, the loader just skips that theme
func test_every_mission_theme_has_a_file() -> void:
	var theme_files := _list_json(THEMES_DIR)
	for file_name in _list_json(MISSIONS_DIR):
		var data = _read_json(MISSIONS_DIR + file_name)
		for theme_name in data.get("themes", []):
			var expected := str(theme_name).to_lower() + ".json"
			assert_true(expected in theme_files, "%s uses unknown theme: %s" % [file_name, theme_name])
			
# after bucket filtering there must still be enough words to fill word_count
func test_every_mission_builds_a_full_word_pool() -> void:
	for file_name in _list_json(MISSIONS_DIR):
		var data = _read_json(MISSIONS_DIR + file_name)
		var words := WordListLoader.build_mission_words(data)
		assert_eq(words.size(), int(data["word_count"]), file_name + " ran short of words")

func test_mission_words_respect_allowed_buckets() -> void:
	for file_name in _list_json(MISSIONS_DIR):
		var data = _read_json(MISSIONS_DIR + file_name)
		# JSON numbers load as floats, so convert before comparing
		var allowed: Array = []
		for bucket in data.get("allowed_buckets", []):
			allowed.append(int(bucket))
		if allowed.is_empty():
			continue
		for word in WordListLoader.build_mission_words(data):
			var bucket := TypingController.get_ammo_reward_for_word(word)
			assert_true(bucket in allowed, "%s gave %s (bucket %d)" % [file_name, word, bucket])
			
			
# GDD §5.1: mission 1 is the tutorial, so no word over 10 letters
func test_mission_1_words_are_short() -> void:
	var data = _read_json(MISSIONS_DIR + "mission1_words.json")
	for word in WordListLoader.build_mission_words(data):
		assert_lte(word.length(), 10, "mission 1 has a long word: " + word)
