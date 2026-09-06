class_name MistakeSystem
extends Node

@onready var ammo_system: AmmoSystem = $"../AmmoSystem"
@onready var typing_controller: Node = $"../TypingController"
@onready var weapon_controller: WeaponController = $"../World/WeaponController"
@onready var mistakes_label: Label = $"../HUD/HUDRoot/TypingPanel/MistakePanel/MistakeMargin/MistakesLabel"
@onready var ability_status_label: Label = $"../HUD/HUDRoot/CombatUtilityPanel/CombatUtilityMargin/CombatUtilityContent/AbilitySection/AbilityStatusLabel"
@onready var ability_combo_bar: ProgressBar = $"../HUD/HUDRoot/CombatUtilityPanel/CombatUtilityMargin/CombatUtilityContent/AbilitySection/ProgressBar"

# duration of a weapon jam in seconds — base value, overridden by the
# Jam Duration upgrade (#25) in _ready()
var jam_cooldown: float = 2.0

var mistake_count: int = 0
var jam_time: float = 2.0

var combo: int = 0
var COMBO_MAX := 5

# Mistake Leniency upgrade (#25): consecutive mistakes tolerated before one
# is actually charged against ammo. Base value 1 matches the original
# design (every mistake costs a bullet).
var mistakes_before_ammo_loss: int = 1
var mistakes_since_ammo_loss: int = 0

func _ready() -> void:
	typing_controller.typing_mistake.connect(_typing_mistake)
	typing_controller.correct_stroke.connect(_correct_stroke)
	typing_controller.target_unregistered.connect(_combo_increment)
	
	_apply_upgrades()
	jam_time = jam_cooldown


# reads current values from UpgradeState/UpgradeCatalog (#25). Safe to call
# again later if upgrades can be purchased mid-run in a future milestone.
func _apply_upgrades() -> void:
	jam_cooldown = UpgradeState.get_upgrade_value("jam_duration")
	mistakes_before_ammo_loss = UpgradeState.get_upgrade_value("mistake_leniency")


func _process(delta: float) -> void:
	# count down only while the weapon is jammed
	if weapon_controller.set_jammed:
		jam_time -= delta

		if jam_time <= 0.0:
			_reset_jam()


func _reset_jam() -> void:
	# restore the weapon and reset the jam timer
	set_jam(false)
	count_check()
	jam_time = jam_cooldown


func _combo_increment() -> void:
	combo += 1
	
	if combo >= COMBO_MAX:
		AbilityState.set_charged(true)
		combo_reset()
	
	update_combo_HUD()


func _typing_mistake() -> void:
	# Mistake Leniency (#25): only charge ammo once this many consecutive
	# mistakes have happened. Base level (1) reproduces the original
	# behaviour of losing ammo on every single mistake, jammed or not.
	mistakes_since_ammo_loss += 1
	if mistakes_since_ammo_loss >= mistakes_before_ammo_loss:
		ammo_system.consume_ammunition(1)
		combo_reset()
		mistakes_since_ammo_loss = 0

	# mistakes made during a jam do not build toward another jam
	if weapon_controller.set_jammed:
		return

	mistake_count += 1
	count_check()


func _correct_stroke() -> void:
	# typing during a jam should not change the jam display
	if weapon_controller.set_jammed:
		return

	# a correct keystroke breaks the consecutive mistake streak
	mistake_count = 0
	mistakes_since_ammo_loss = 0
	count_check()


func count_check() -> void:
	# update the counter and trigger a jam at three mistakes
	print("consecutive count: " + str(mistake_count))
	mistakes_label.text = "MISTAKES: " + str(mistake_count) + " / 3"

	if mistake_count >= 3:
		mistake_count = 0
		set_jam(true)


func set_jam(jam_state: bool) -> void:
	# update the weapon state and hud
	weapon_controller.set_jammed = jam_state

	if jam_state:
		print("JAMMED")
		mistakes_label.text = "JAMMED"
	else:
		print("UNJAMMED")


func combo_reset() -> void:
	combo = 0
	update_combo_HUD()


func update_combo_HUD() -> void:
	ability_status_label.text = "COMBO: "+ str(combo) +" / "+ str(COMBO_MAX)
	ability_combo_bar.max_value = COMBO_MAX
	ability_combo_bar.value = combo
