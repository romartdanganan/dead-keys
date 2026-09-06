class_name AbilityCatalog
extends RefCounted

# ability data table (GDD §2.2.3). "implemented" gates whether it can be
# selected this sprint, #24 scope is Spread Shot only, rest are backlog.

const ABILITIES: Array[Dictionary] = [
	{
		"id": "spread_shot",
		"display_name": "Spread Shot",
		"description": "Next shot after Combo charges fires 3 bullets in a cone instead of 1.",
		"implemented": true,
		"cost": 0,
	},
	{
		"id": "ricochet",
		"display_name": "Ricochet",
		"description": "Next shot after Combo charges bounces to 2 nearby zombies after its first hit, 3 zombies hit total.",
		"implemented": true,
		"cost": 200,
	},
	{"id": "ability_3", "display_name": "Freeze Round", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
	{"id": "ability_4", "display_name": "Piercing Shot", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
	{"id": "ability_5", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
	{"id": "ability_6", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
	{"id": "ability_7", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
	{"id": "ability_8", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false, "cost": 0},
]


static func get_ability(ability_id: String) -> Dictionary:
	for ability: Dictionary in ABILITIES:
		if ability.id == ability_id:
			return ability
	return {}
