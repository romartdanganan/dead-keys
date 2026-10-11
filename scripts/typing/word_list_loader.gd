class_name WordListLoader
extends RefCounted

# builds a mission word pool from shared theme files (#43)
# file formats and bucket rules: resources/word_lists/README.md

#theme file format: {"theme: "suburb", words" : ["gate, "home" ...]}
#mission file format: {"themes: ["suburb", "zombie"], "word_count":20, "allowed_bucket: [1,2,3]}
#bucket follow GD 2.2.1 tiers from TyperController.get_ammo>reward_for_word,
# so 1 ammo = 3-4 words, 2 ammo = 5-7 words, 3 = 8-10, 4 = 11+


const THEMES_DIR := "res://resources/word_lists/themes/"

#theme word files -> contain array of words, filled once per game session
static var _theme_cache: Dictionary = {}

#reads every theme file once, later call reuse the cache 
static func load_themes() -> void: 
	if not _theme_cache.is_empty():
		return
	
	for file_name in DirAccess.get_files_at(THEMES_DIR):
		if not file_name.ends_with(".json"):
			continue
		var parsed = _read_json(THEMES_DIR + file_name)
		if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("words"):
			push_warning("WordListLoader: skipping malformed theme file " + file_name)
			continue
		
		var words: Array[String] = []
		for entry in parsed["words"]:
			if typeof(entry) == TYPE_STRING:
				words.append(entry.to_lower())
				
		_theme_cache[file_name.get_basename().to_lower()] = words		
		
		
		
static func build_mission_words(mission_data: Dictionary) -> Array[String]:
	load_themes()

	# merge themes, skipping words already added from another theme
	var pool: Array[String] = []
	for theme_name in mission_data.get("themes", []):
		var key := str(theme_name).to_lower()
		if not _theme_cache.has(key):
			push_warning("WordListLoader: unknown theme: " + key)
			continue
		for word in _theme_cache[key]:
			if not pool.has(word):
				pool.append(word)

	# JSON numbers load as floats, so convert to int before comparing
	var allowed_buckets: Array[int] = []
	for bucket in mission_data.get("allowed_buckets", []):
		allowed_buckets.append(int(bucket))

	# no allowed_buckets means every bucket is allowed
	if not allowed_buckets.is_empty():
		var filtered: Array[String] = []
		for word in pool:
			if TypingController.get_ammo_reward_for_word(word) in allowed_buckets:
				filtered.append(word)
		pool = filtered

	# random sample, so each playthrough gets a slightly different mix
	var word_count := int(mission_data.get("word_count", pool.size()))
	pool.shuffle()
	if word_count < pool.size():
		pool.resize(word_count)
	elif word_count > pool.size():
		push_warning("WordListLoader: wanted %d words but only %d available" % [word_count, pool.size()])

	return pool

#GUT tests start from an empty cache 
static func clear_cache() -> void:
	_theme_cache.clear()
		
	
static func _read_json(path: String) -> Variant: 
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())
