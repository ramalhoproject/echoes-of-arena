extends Resource
class_name CharacterData

@export_category("Info")
@export var character_id: String
@export var display_name: String

@export_category("Stats")
@export var max_health: int = 100
@export var move_speed: int = 300
@export var jump_force: int = 550

@export_category("Visual")
@export var texture: Texture2D

@export_category("Abilities")
@export var abilities: Array[String] = []
