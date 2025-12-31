extends Node
# Script responsável apenas pela identidade visual do player.
# Controla a geração, aplicação e sincronização da cor do player no multiplayer.

@export var sprite: Sprite2D
# Referência ao Sprite2D do Player.

@export var playerNameLabel: Label
# Referência ao Label do Player.

var playerColor: Color
# Armazena a cor atual do player.
# Esta variável é sincronizada via RPC para os outros peers.

func _ready():
	# Obtém a referência ao nó pai (Player - CharacterBody2D)
	var player := get_parent()
	
	# Verifica se este peer possui autoridade sobre o player.
	# Apenas o player local pode definir sua própria cor.
	if not player.is_multiplayer_authority():
		return
	
	# Gera uma cor aleatória utilizando o modelo HSV
	# Hue (matiz) aleatório, saturação alta e brilho alto
	playerColor = Color.from_hsv(randf(), 0.8, 0.9)
	
	# Aplica a cor localmente no sprite
	_apply_color(playerColor)
	
	# Envia a cor gerada para todos os outros peers
	# call_local garante que o método também seja executado localmente
	rpc("_set_color", playerColor)

# No script do PLAYER (Identidade)
func setup_identity(data: Dictionary):
	# Esta função será chamada logo após o spawn
	playerNameLabel.text = data.nick
	# Se a cor também vier no data, você evita usar RPCs extras

@rpc("any_peer", "call_local")
func _set_color(color: Color):
	# Recebe a cor enviada pelo peer com autoridade
	# e atualiza a variável local
	playerColor = color
	
	# Aplica a cor recebida no sprite
	_apply_color(color)

func _apply_color(color: Color):
	# Função auxiliar responsável apenas por aplicar a cor no sprite
	# Verifica se o sprite existe antes de aplicar
	if sprite:
		sprite.modulate = color
