extends Node

@export var word_label: RichTextLabel

var current_word: String = "code"
var typed_index: int = 0

const LETTERS := "abcdefghijklmnopqrstuvwxyz"
var test_words: Array[String] = ["code", "walker", "undead", "keyboard"]

signal word_completed(word: String, ammunition_reward: int)

func _ready() -> void:
	assign_new_word()
	
	

#deal with the last input, catch the keypress and print out the unicode
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey): # key pressed or release
		return
	if not event.pressed or event.echo: #ignore spam keys and pressed
		return
	if event.unicode == 0: #allow arrows/espace keys 
		return
	
	var typed := char(event.unicode).to_lower()
	
	if not LETTERS.contains(typed): #reject numbers and etc 
		return 
	
	get_viewport().set_input_as_handled() #letters only work for typing
	check_letter(typed)
		
func check_letter(typed: String) -> void:
	var expected := current_word[typed_index].to_lower()
	
	if typed == expected:
		typed_index += 1 
		update_label()
		
		print ("correct - progress: ", typed_index, "/",current_word.length())
		
		#check our typed_index to current word pos
		if typed_index >= current_word.length():
			complete_word()
	else: 
		print("mistake - expected ", expected," got ", typed)

#function: when a word is finished, refresh to a new one and gain ammo
func complete_word() -> void:
	print("WORD COMPLETE: ", current_word)
	word_completed.emit(current_word, 1)
	assign_new_word()
		
#chose a word
func assign_new_word() -> void:
	current_word = test_words.pick_random()
	typed_index = 0
	update_label() 
	
	
#update the label based on the current word pos type correctly
func update_label() -> void:
	var done := current_word.substr(0, typed_index)
	var remaining := current_word.substr(typed_index)
	word_label.text = "[color=#5aa9e6]%s[/color]%s" % [done, remaining]
