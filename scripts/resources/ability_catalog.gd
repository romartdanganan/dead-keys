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
	},
	{"id": "ability_2", "display_name": "Ricochet", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_3", "display_name": "Freeze Round", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_4", "display_name": "Piercing Shot", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_5", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_6", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_7", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false},
	{"id": "ability_8", "display_name": "LOCKED", "description": "Coming in a future sprint.", "implemented": false},
]


static func get_ability(ability_id: String) -> Dictionary:
	for ability: Dictionary in ABILITIES:
		if ability.id == ability_id:
			return ability
	return {}
