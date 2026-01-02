extends AnimatedSprite2D
class_name PlayerAnimations
# Responsável por toda animação do player

# ==============================================================================
# RECURSOS (Preload)
# ==============================================================================
var cryomancerAnimation = preload("res://characters/CryomancerAnimation.tres")
var assassinAnimation = preload("res://characters/AssassinAnimation.tres")

# ==============================================================================
# REFERÊNCIAS
# ==============================================================================
@onready var player : CharacterBody2D = $".."

# ==============================================================================
# CICLO DE VIDA E REDE
# ==============================================================================
func _enter_tree() -> void:
	# Se formos o dono deste player, definimos nossa escolha local e sincronizamos
	if is_multiplayer_authority():
		var escolha = NetworkManager.selectedCharacter
		_aplicar_sprite_frames(escolha)
		
		# Sincroniza para quem já estava na partida
		rpc("_sincronizar_personagem", escolha)

func _process(_delta: float) -> void:
	# Apenas o dono do player decide qual animação deve tocar localmente.
	# O MultiplayerSynchronizer deve sincronizar a propriedade 'animation' e 'flip_h'.
	if not is_multiplayer_authority():
		return
	
	_handle_flip()
	_handle_animation_state()

# ==============================================================================
# LÓGICA DE VISUAL E ANIMAÇÃO
# ==============================================================================
## Chamada externamente (ex: pelo MapNetwork) para garantir o visual no spawn
func _setup_visual(personagem: String) -> void:
	_aplicar_sprite_frames(personagem)

func _handle_flip() -> void:
	# Gerencia a direção do Sprite baseado na velocidade horizontal
	if player.velocity.x != 0:
		flip_h = player.velocity.x < 0

func _handle_animation_state() -> void:
	# 1. Lógica para estado No Ar
	if not player.is_on_floor():
		if player.velocity.y < 0:
			play("jumping")
		else:
			play("falling")
		return

	# 2. Lógica para estado No Chão
	var horizontalSpeed = abs(player.velocity.x)
	
	if horizontalSpeed == 0:
		play("idle")
	elif horizontalSpeed > player.speed / 2.0:
		play("run")
	else:
		play("walk")

func _aplicar_sprite_frames(personagem: String) -> void:
	# Troca o recurso de SpriteFrames baseado na escolha do jogador
	if personagem == "cryomancer":
		sprite_frames = cryomancerAnimation
	elif personagem == "assassin":
		sprite_frames = assassinAnimation
	
	play("idle")

# ==============================================================================
# COMUNICAÇÃO DE REDE (RPC)
# ==============================================================================
@rpc("any_peer", "call_local", "reliable")
func _sincronizar_personagem(personagem: String) -> void:
	_aplicar_sprite_frames(personagem)
