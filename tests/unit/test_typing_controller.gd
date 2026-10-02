extends GutTest

# word matching, mistakes, completion and word assignment in TypingController

var typing: TypingController


func before_each() -> void:
	typing = TypingController.new()
	# empty path keeps the built in fallback words, no file needed
	typing.word_list_path = ""
	add_child_autofree(typing)


func _add_target(word: String, kind: String = "zombie") -> Node:
	var target := Node2D.new()
	var label := RichTextLabel.new()
	target.add_child(label)
	add_child_autofree(target)
	typing.register_target(target, label, kind)
	# force a known word so the test can type it
	typing.active_targets[typing.active_targets.size() - 1]["word"] = word
	return target


func _type(text: String) -> void:
	for letter in text:
		typing.check_letter(letter)


func test_correct_letters_build_the_prefix() -> void:
	_add_target("code")
	watch_signals(typing)

	_type("co")

	assert_eq(typing.typed_prefix, "co")
	assert_signal_emit_count(typing, "correct_stroke", 2)


func test_wrong_letter_is_a_mistake_and_keeps_the_prefix() -> void:
	_add_target("code")
	watch_signals(typing)

	_type("cx")

	assert_eq(typing.typed_prefix, "c")
	assert_signal_emitted(typing, "typing_mistake")


func test_finishing_a_word_emits_its_ammo_reward() -> void:
	_add_target("code")
	watch_signals(typing)

	_type("code")

	assert_signal_emitted_with_parameters(typing, "word_completed", ["code", 1])
	assert_eq(typing.typed_prefix, "")


func test_finished_zombie_gets_a_different_new_word() -> void:
	_add_target("code")
	_type("code")

	assert_eq(typing.active_targets.size(), 1)
	assert_ne(typing.active_targets[0]["word"], "code")


func test_finishing_a_supply_word_claims_and_unregisters_it() -> void:
	var crate := _add_target("crate", "supply")
	watch_signals(typing)

	_type("crate")

	assert_signal_emitted_with_parameters(typing, "supply_word_completed", [crate, "crate"])
	assert_eq(typing.active_targets.size(), 0)


func test_registering_the_same_target_twice_is_ignored() -> void:
	var target := _add_target("code")
	var label: RichTextLabel = typing.active_targets[0]["label"]

	typing.register_target(target, label)

	assert_eq(typing.active_targets.size(), 1)


func test_active_targets_never_share_a_word() -> void:
	for i in 5:
		var target := Node2D.new()
		var label := RichTextLabel.new()
		target.add_child(label)
		add_child_autofree(target)
		typing.register_target(target, label)

	var words: Array[String] = []
	for target_data in typing.active_targets:
		assert_false(target_data["word"] in words, "duplicate word: " + target_data["word"])
		words.append(target_data["word"])


func test_unregister_resets_the_typed_prefix() -> void:
	var target := _add_target("code")
	_type("co")

	typing.unregister_target(target)

	assert_eq(typing.typed_prefix, "")
	assert_eq(typing.active_targets.size(), 0)


func test_typed_prefix_is_highlighted_on_the_label() -> void:
	_add_target("code")
	_type("co")

	var label: RichTextLabel = typing.active_targets[0]["label"]
	assert_string_contains(label.text, "[color=")
