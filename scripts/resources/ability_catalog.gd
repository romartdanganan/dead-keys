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
	{
		"id": "freeze_round",
		"display_name": "Freeze Round",
		"description": "Next shot after Combo charges fully freezes the hit zombie and nearby zombies in a small radius for a few seconds.",
		"implemented": true,
		"cost": 200,
	},
	{
		"id": "piercing_shot",
		"display_name": "Piercing Shot",
		"description": "Next shot after Combo charges pierces every zombie in its path with no limit, until it leaves the arena.",
		"implemented": true,
		"cost": 200,
	},
	# replaces the four locked placeholder slots
	{
		"id": "explosive_round",
		"display_name": "Explosive Round",
		"description": "Next shot after Combo charges explodes on impact, damaging every zombie in a small radius.",
		"implemented": true,
		"cost": 200,
	},
	{
		"id": "heavy_round",
		"display_name": "Heavy Round",
		"description": "Next shot after Combo charges deals 5x damage to the zombie it hits.",
		"implemented": true,
		"cost": 200,
	},
	{
		"id": "homing_shot",
		"display_name": "Homing Shot",
		"description": "Next shot after Combo charges curves towards the nearest zombie.",
		"implemented": true,
		"cost": 200,
	},
	{
		"id": "shockwave_round",
		"display_name": "Shockwave Round",
		"description": "Next shot after Combo charges knocks the hit zombie and nearby zombies back.",
		"implemented": true,
		"cost": 200,
	},
]


static func get_ability(ability_id: String) -> Dictionary:
	for ability: Dictionary in ABILITIES:
		if ability.id == ability_id:
			return ability
	return {}
