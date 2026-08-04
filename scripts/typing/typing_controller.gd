extends Node

@export var word_label: RichTextLabel

var current_word: String = "code"
var typed_index: int = 0
var typing_enabled: bool = true

const LETTERS := "abcdefghijklmnopqrstuvwxyz"
var test_words: Array[String] = ["code", "walker", "undead", "keyboard"]

signal word_completed(word: String, ammunition_reward: int)

func _ready() -> void:
	typing_enabled = is_instance_valid(word_label)
	
	if typing_enabled:
		assign_new_word()
	
	

#deal with the last input, catch the keypress and print out the unicode
func _unhandled_input(event: InputEvent) -> void:
	#makes sure typing is not enabled for freed object
	if not typing_enabled: 
		return
	if not is_instance_valid(word_label):
		clear_target()
		return
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
	# safety checks for finished words and objects
	if current_word.is_empty():
		return
	if typed_index >= current_word.length():
		return
		
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
	
	# temporary debugging behaviour for the dummy target, please remove when integrating the walker
	assign_new_word()
		
#chose a word
func assign_new_word() -> void:
	current_word = test_words.pick_random()
	typed_index = 0
	update_label() 
	
	
#update the label based on the current word pos type correctly
func update_label() -> void:
	# prevents a crash after the target is freed and its WordLabel are freed
	if not is_instance_valid(word_label):
		clear_target()
		return
	var done := current_word.substr(0, typed_index)
	var remaining := current_word.substr(typed_index)
	word_label.text = "[color=#5aa9e6]%s[/color]%s" % [done, remaining]
	

func clear_target() -> void:
	typing_enabled = false
	current_word = ""
	typed_index = 0
	word_label = null

	print("Typing disabled: no active target")
