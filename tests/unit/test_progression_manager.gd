extends GutTest

# gold spending and ability/upgrade purchases, purchases save so the real save is backed up

const ProgressionBackup := preload("res://tests/helpers/progression_backup.gd")
const AbilityCatalog := preload("res://scripts/resources/ability_catalog.gd")
const UpgradeCatalog := preload("res://scripts/resources/upgrade_catalog.gd")

var _backup := ProgressionBackup.new()


func before_each() -> void:
	_backup.backup()
	ProgressionManager.gold = 1000
	ProgressionManager.owned_abilities = {"spread_shot": true}
	ProgressionManager.upgrade_levels = {}


func after_each() -> void:
	_backup.restore()


func test_add_gold_increases_gold_and_emits_signal() -> void:
	watch_signals(ProgressionManager)
	ProgressionManager.add_gold(50)

	assert_eq(ProgressionManager.gold, 1050)
	assert_signal_emitted_with_parameters(ProgressionManager, "gold_changed", [1050])


func test_add_gold_ignores_non_positive_amounts() -> void:
	ProgressionManager.add_gold(0)
	ProgressionManager.add_gold(-20)
	assert_eq(ProgressionManager.gold, 1000)


func test_spend_gold_fails_without_spending_when_unaffordable() -> void:
	assert_false(ProgressionManager.spend_gold(5000))
	assert_eq(ProgressionManager.gold, 1000)


func test_is_ability_owned_only_true_for_owned_abilities() -> void:
	assert_true(ProgressionManager.is_ability_owned("spread_shot"))
	assert_false(ProgressionManager.is_ability_owned("ricochet"))


func test_purchase_ability_spends_its_cost_and_owns_it() -> void:
	var cost: int = AbilityCatalog.get_ability("ricochet").cost

	assert_true(ProgressionManager.purchase_ability("ricochet"))
	assert_true(ProgressionManager.is_ability_owned("ricochet"))
	assert_eq(ProgressionManager.gold, 1000 - cost)


func test_purchase_ability_twice_does_not_charge_again() -> void:
	ProgressionManager.purchase_ability("ricochet")
	var gold_after_first := ProgressionManager.gold

	assert_false(ProgressionManager.purchase_ability("ricochet"))
	assert_eq(ProgressionManager.gold, gold_after_first)


func test_purchase_ability_fails_when_unaffordable() -> void:
	ProgressionManager.gold = 10
	assert_false(ProgressionManager.purchase_ability("ricochet"))
	assert_false(ProgressionManager.is_ability_owned("ricochet"))
	assert_eq(ProgressionManager.gold, 10)


func test_purchase_ability_fails_for_unknown_id() -> void:
	assert_false(ProgressionManager.purchase_ability("not_a_real_ability"))
	assert_eq(ProgressionManager.gold, 1000)


# skips itself once every slot is implemented
func test_purchase_ability_fails_for_unimplemented_ability() -> void:
	for ability: Dictionary in AbilityCatalog.ABILITIES:
		if not ability.implemented:
			assert_false(ProgressionManager.purchase_ability(ability.id))
			assert_eq(ProgressionManager.gold, 1000)
			return
	pass_test("every ability is implemented, nothing to check")


func test_purchase_upgrade_spends_cost_and_raises_level() -> void:
	var cost := UpgradeCatalog.get_cost_for_next_level("fire_rate", 0)

	assert_true(ProgressionManager.purchase_upgrade("fire_rate"))
	assert_eq(ProgressionManager.get_upgrade_level("fire_rate"), 1)
	assert_eq(ProgressionManager.gold, 1000 - cost)


func test_purchase_upgrade_fails_when_maxed() -> void:
	ProgressionManager.upgrade_levels["fire_rate"] = UpgradeCatalog.get_max_level("fire_rate")

	assert_false(ProgressionManager.purchase_upgrade("fire_rate"))
	assert_eq(ProgressionManager.gold, 1000)


func test_purchase_upgrade_fails_when_unaffordable() -> void:
	ProgressionManager.gold = 0
	assert_false(ProgressionManager.purchase_upgrade("fire_rate"))
	assert_eq(ProgressionManager.get_upgrade_level("fire_rate"), 0)
	

func test_only_mission_1_unlocked_on_fresh_save() -> void:
	ProgressionManager.highest_unlocked = 1
	
	assert_true(ProgressionManager.is_mission_unlocked(1))
	assert_false(ProgressionManager.is_mission_unlocked(2))
	
func test_completing_mission_1_unlocks_only_mission_2() -> void:
	ProgressionManager.highest_unlocked = 1
	ProgressionManager.unlock_next_mission(1)
	
	assert_true(ProgressionManager.is_mission_unlocked(2))
	assert_false(ProgressionManager.is_mission_unlocked(3))
	
func test_replaying_earlier_mission_does_not_relock() -> void:
	ProgressionManager.highest_unlocked = 6
	ProgressionManager.unlock_next_mission(1)
	assert_eq(ProgressionManager.highest_unlocked, 6)
	
