extends Node
class_name PlayerVisual
# Responsável por toda parte visual do jogador

# ==============================================================================
# VARIÁVEIS EXPORT (@export)
# ==============================================================================
@export_group("Referências de UI")
@export var sprite : Sprite2D
@export var playerNameLabel : Label

# ==============================================================================
# VARIÁVEIS DE ESTADO E REFERÊNCIAS
# ==============================================================================
@onready var player : CharacterBody2D = $".."

var playerColor : Color

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Define o Z-Index baseado na autoridade:
	# O player local fica visualmente à frente dos outros jogadores (peers)
	if player.is_multiplayer_authority():
		player.z_index = 10
	else:
		player.z_index = 1

# ==============================================================================
# LÓGICA DE IDENTIDADE (MULTIPLAYER)
# ==============================================================================
## Função chamada pelo Spawner em todos os clientes no momento da criação do player
func _setup_identity(data: Dictionary) -> void:
	# Definimos os dados básicos que todos precisam ver
	playerNameLabel.text = data.nick
	playerColor = data.color
	
	# Configuração visual do Label de Nome
	playerNameLabel.add_theme_color_override("font_color", playerColor)
	playerNameLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	playerNameLabel.add_theme_constant_override("outline_size", 8)
	
	_apply_color(playerColor)

# ==============================================================================
# COMUNICAÇÃO DE REDE (RPC)
# ==============================================================================
## RPC para atualização de cor em tempo real (caso mude após o spawn)
@rpc("any_peer", "call_remote", "reliable")
func _set_color_rpc(color: Color) -> void:
	playerColor = color
	playerNameLabel.add_theme_color_override("font_color", color)
	_apply_color(color)

# ==============================================================================
# MÉTODOS AUXILIARES
# ==============================================================================
func _apply_color(color: Color) -> void:
	# Modula a cor do Sprite para aplicar a identidade visual no personagem
	if sprite:
		sprite.modulate = color
