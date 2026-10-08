extends CanvasLayer

# boss name and health bar under the wave counter, only visible while a boss is alive

# enemy ids that count as bosses, a new boss only needs adding here
const BOSS_IDS: Array[String] = ["tank"]

@onready var panel: PanelContainer = $Root/Panel
@onready var name_label: Label = $Root/Panel/Margin/Content/NameLabel
@onready var bar: ProgressBar = $Root/Panel/Margin/Content/HealthBar

var _boss: Zombie = null


func _ready() -> void:
	panel.visible = false


func setup(zombie_manager: ZombieManager) -> void:
	zombie_manager.zombie_spawned.connect(_on_zombie_spawned)


static func is_boss(type: EnemyTypeDef) -> bool:
	return type != null and type.enemy_id in BOSS_IDS


func _on_zombie_spawned(zombie: Zombie) -> void:
	if not is_boss(zombie.enemy_type):
		return
	_boss = zombie
	if not zombie.died.is_connected(_on_boss_died):
		zombie.died.connect(_on_boss_died)
	name_label.text = zombie.enemy_type.display_name.to_upper()
	bar.max_value = zombie.get_max_health()
	bar.value = zombie.health
	panel.visible = true


# polled so medic healing shows too, not just damage
func _process(_delta: float) -> void:
	if _boss != null:
		bar.value = _boss.health


func _on_boss_died(zombie: Zombie) -> void:
	if zombie != _boss:
		return
	_boss = null
	panel.visible = false
