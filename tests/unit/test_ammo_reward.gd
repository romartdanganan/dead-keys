extends GutTest

# covers the word length to ammo reward tiers from GDD 2.2.1


func test_short_words_give_one_bullet() -> void:
	assert_eq(TypingController.get_ammo_reward_for_word("code"), 1)
	assert_eq(TypingController.get_ammo_reward_for_word("cat"), 1)


func test_medium_words_give_two_bullets() -> void:
	assert_eq(TypingController.get_ammo_reward_for_word("brain"), 2)
	assert_eq(TypingController.get_ammo_reward_for_word("defence"), 2)


func test_long_words_give_three_bullets() -> void:
	assert_eq(TypingController.get_ammo_reward_for_word("keyboard"), 3)
	assert_eq(TypingController.get_ammo_reward_for_word("barricade"), 3)


func test_very_long_words_give_four_bullets() -> void:
	assert_eq(TypingController.get_ammo_reward_for_word("unbelievable"), 4)
	assert_eq(TypingController.get_ammo_reward_for_word("contamination"), 4)


# tier edges so an off by one in the boundaries gets caught
func test_tier_boundaries() -> void:
	assert_eq(TypingController.get_ammo_reward_for_word("abcd"), 1)
	assert_eq(TypingController.get_ammo_reward_for_word("abcde"), 2)
	assert_eq(TypingController.get_ammo_reward_for_word("abcdefg"), 2)
	assert_eq(TypingController.get_ammo_reward_for_word("abcdefgh"), 3)
	assert_eq(TypingController.get_ammo_reward_for_word("abcdefghij"), 3)
	assert_eq(TypingController.get_ammo_reward_for_word("abcdefghijk"), 4)
