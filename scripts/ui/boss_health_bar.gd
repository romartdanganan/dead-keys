extends CanvasLayer

# boss name and health bar under the wave counter, only visible while a boss is alive
# the phase marks at 66% and 33% are ColorRect nodes on the bar in the scene

# enemy ids that count as bosses, a new boss only needs adding here
const BOSS_IDS: Array[String] = ["tank"]
# how far above its resting spot the bar starts when it slides in
const SLIDE_DISTANCE: float = 40.0

@onready var panel: PanelContainer = $Root/Panel
@onready var name_label: Label = $Root/Panel/Margin/Content/NameLabel
@onready var bar: ProgressBar = $Root/Panel/Margin/Content/HealthBar

var _boss: Zombie = null
var _show_tween: Tween
var _rest_top: float
var _rest_bottom: float


func _ready() -> void:
	panel.visible = false
	_rest_top = panel.offset_top
	_rest_bottom = panel.offset_bottom


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
	_slide_in()


# drops the bar in from above instead of popping into view
func _slide_in() -> void:
	if _show_tween != null and _show_tween.is_valid():
		_show_tween.kill()
	panel.modulate.a = 0.0
	panel.offset_top = _rest_top - SLIDE_DISTANCE
	panel.offset_bottom = _rest_bottom - SLIDE_DISTANCE
	_show_tween = create_tween().set_parallel(true)
	_show_tween.tween_property(panel, "modulate:a", 1.0, 0.4)
	_show_tween.tween_property(panel, "offset_top", _rest_top, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_show_tween.tween_property(panel, "offset_bottom", _rest_bottom, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# polled so medic healing shows too, not just damage
func _process(_delta: float) -> void:
	if _boss != null:
		bar.value = _boss.health


func _on_boss_died(zombie: Zombie) -> void:
	if zombie != _boss:
		return
	_boss = null
	panel.visible = false
