class_name SupplyTextures
extends RefCounted

# maps SupplyCatalog ids to their crate icon, single source of truth so
# every UI/world spot that shows a crate icon stays in sync (#35)

const TEXTURES: Dictionary = {
	"ammo_crate": preload("res://assets/ui/ammo_crate_icon.png"),
	"medical_crate": preload("res://assets/ui/medical_crate_icon.png"),
	"combat_crate": preload("res://assets/ui/combat_crate_icon.png"),
	"emergency_crate": preload("res://assets/ui/emergency_crate_icon.png"),
}


static func get_texture(supply_id: String) -> Texture2D:
	return TEXTURES.get(supply_id, null)
