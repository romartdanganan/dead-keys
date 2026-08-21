extends GutTest

const SupplyCatalog := preload("res://scripts/resources/supply_catalog.gd")

# SupplyState and UpgradeState are real autoload singletons, not fresh
# instances per test, so their state is captured and restored around every
# test to avoid leaking into other tests or a manual play session running
# in the same editor.

var original_gold: int


func before_each() -> void:
	SupplyState.clear_loadout()
	original_gold = UpgradeState.gold
	UpgradeState.gold = 1000


func after_each() -> void:
	SupplyState.clear_loadout()
	UpgradeState.gold = original_gold


# a normal purchase into an empty slot should succeed and spend the
# crate's exact listed cost, no more, no less
func test_purchase_into_slot_succeeds_and_spends_gold() -> void:
	var purchased := SupplyState.purchase_into_slot(0, "ammo_crate")
	assert_true(purchased)
	assert_eq(SupplyState.get_slot(0), "ammo_crate")
	assert_eq(UpgradeState.gold, 1000 - SupplyCatalog.get_supply("ammo_crate").cost)


# regression test for the overwrite bug found during manual testing:
# buying into an already-occupied slot must fail and refund nothing,
# since nothing was spent
func test_purchase_into_slot_fails_when_slot_already_occupied() -> void:
	SupplyState.purchase_into_slot(0, "ammo_crate")
	var gold_after_first_purchase := UpgradeState.gold

	var purchased_again := SupplyState.purchase_into_slot(0, "medical_crate")

	assert_false(purchased_again)
	assert_eq(SupplyState.get_slot(0), "ammo_crate")
	assert_eq(
		UpgradeState.gold,
		gold_after_first_purchase,
		"gold should not be spent on a failed purchase"
	)


# can't buy what you can't afford, slot should stay empty
func test_purchase_into_slot_fails_when_gold_is_insufficient() -> void:
	UpgradeState.gold = 10
	var purchased := SupplyState.purchase_into_slot(0, "emergency_crate")
	assert_false(purchased)
	assert_eq(SupplyState.get_slot(0), "")


# selling an equipped supply (the hover-to-sell flow) should refund
# exactly what was paid and empty the slot
func test_sell_slot_refunds_the_original_cost() -> void:
	SupplyState.purchase_into_slot(0, "combat_crate")
	var gold_after_purchase := UpgradeState.gold

	SupplyState.sell_slot(0)

	assert_eq(SupplyState.get_slot(0), "")
	assert_eq(UpgradeState.gold, gold_after_purchase + SupplyCatalog.get_supply("combat_crate").cost)


# selling nothing should be a harmless no-op, not an error or a false refund
func test_sell_slot_on_an_empty_slot_does_nothing() -> void:
	var gold_before := UpgradeState.gold
	SupplyState.sell_slot(0)
	assert_eq(UpgradeState.gold, gold_before)


# used by the shop UI to auto-select where the next purchase should go
func test_first_empty_slot_finds_the_correct_index() -> void:
	assert_eq(SupplyState.first_empty_slot(), 0)
	SupplyState.purchase_into_slot(0, "ammo_crate")
	assert_eq(SupplyState.first_empty_slot(), 1)


# once all 3 slots are filled, there is no empty slot left to return
func test_first_empty_slot_returns_negative_one_when_full() -> void:
	SupplyState.purchase_into_slot(0, "ammo_crate")
	SupplyState.purchase_into_slot(1, "medical_crate")
	SupplyState.purchase_into_slot(2, "combat_crate")
	assert_eq(SupplyState.first_empty_slot(), -1)


# supplies are repurchased every mission per GDD §2.6, clear_loadout()
# is what enforces that when a mission ends
func test_clear_loadout_empties_all_three_slots() -> void:
	SupplyState.purchase_into_slot(0, "ammo_crate")
	SupplyState.purchase_into_slot(1, "medical_crate")

	SupplyState.clear_loadout()

	assert_eq(SupplyState.get_slot(0), "")
	assert_eq(SupplyState.get_slot(1), "")
	assert_eq(SupplyState.get_slot(2), "")
