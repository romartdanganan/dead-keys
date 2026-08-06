# TO DO
extends Resource
class_name MissionConfigDef

@export var mission_id: String = ""
@export var mission_name: String = ""
@export var word_list: Resource           
@export var waves: Array[WaveEntry] = []
@export var base_coin_reward: int = 50   
@export var background_scene_path: String = ""
