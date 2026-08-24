class_name SupplyCatalog
extends RefCounted

# supply crate data table (GDD §2.2.4). costs follow the GDD's documented
# 40-120 coin range (§2.6); exact effect numbers aren't specified in the
# GDD, so the values below are a first-pass judgment call, flagged for
# review in the MR.

const SUPPLIES: Array[Dictionary] = [
	{
		"id": "ammo_crate",
		"display_name": "Ammo Crate",
		"description": "Refills ammunition to maximum capacity.",
		"cost": 60,
	},
	{
		"id": "medical_crate",
		"display_name": "Medical Crate",
		"description": "Repairs the wall for 50% of its maximum health.",
		"cost": 80,
	},
	{
		"id": "combat_crate",
		"display_name": "Combat Crate",
		"description": "+50% bullet damage for the rest of the mission.",
		"cost": 100,
	},
	{
		"id": "emergency_crate",
		"display_name": "Emergency Crate",
		"description": "Halves wall damage taken for 15 seconds and refills half your ammunition.",
		"cost": 120,
	},
]


static func get_supply(supply_id: String) -> Dictionary:
	for supply: Dictionary in SUPPLIES:
		if supply.id == supply_id:
			return supply
	return {}
