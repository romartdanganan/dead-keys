extends RefCounted
class_name ZombiePool

var _zombie_scene: PackedScene
var _container: Node
var _available: Array[Zombie] = []

func _init(zombie_scene: PackedScene, container: Node) -> void:
	_zombie_scene = zombie_scene
	_container = container

func acquire() -> Zombie:
	if _available.is_empty():
		var zombie: Zombie = _zombie_scene.instantiate()
		_container.add_child(zombie)
		return zombie
	return _available.pop_back()

func release(zombie: Zombie) -> void:
	if not _available.has(zombie):
		_available.append(zombie)

func size() -> int:
	return _available.size()
