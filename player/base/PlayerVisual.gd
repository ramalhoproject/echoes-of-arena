extends Node

@export var sprite: Sprite2D # Se ainda usar para algum detalhe
@export var playerNameLabel: Label
@onready var player: CharacterBody2D = $".."

var playerColor: Color

func _ready():
	# Define o Z-Index baseado na autoridade
	if player.is_multiplayer_authority():
		player.z_index = 10
	else:
		player.z_index = 1

# ESTA FUNÇÃO É A CHAVE
func setup_identity(data: Dictionary):
	# Definimos os dados básicos que todos precisam ver
	playerNameLabel.text = data.nick
	playerColor = data.color
	
	# Aplicamos as cores
	playerNameLabel.add_theme_color_override("font_color", playerColor)
	playerNameLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	playerNameLabel.add_theme_constant_override("outline_size", 8)
	
	_apply_color(playerColor)

@rpc("any_peer", "call_remote", "reliable")
func _set_color_rpc(color: Color):
	playerColor = color
	playerNameLabel.add_theme_color_override("font_color", color)
	_apply_color(color)

func _apply_color(color: Color):
	if sprite:
		sprite.modulate = color
