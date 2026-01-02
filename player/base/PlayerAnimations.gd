extends AnimatedSprite2D

@onready var player: CharacterBody2D = $".."

# Caminhos dos recursos para facilitar a manutenção
var cryomancerAnimation = preload("res://characters/CryomancerAnimation.tres")
var assassinAnimation = preload("res://characters/AssassinAnimation.tres")

func _enter_tree() -> void:
	# 1. Se formos o dono deste player, definimos nossa escolha local
	if is_multiplayer_authority():
		var escolha = NetworkManager.selectedCharacter
		_aplicar_sprite_frames(escolha)
		
		# 2. Avisamos os outros jogadores qual personagem escolhemos
		# (Isso assume que você tem um sistema de sincronização de estado)
		rpc("_sincronizar_personagem", escolha)

func _process(_delta: float) -> void:
	# SE NÃO FOR O DONO DO PLAYER, NÃO EXECUTA A LÓGICA DE DECIDIR ANIMAÇÃO
	# O MultiplayerSynchronizer cuidará de atualizar os outros clientes.
	if not is_multiplayer_authority():
		return
	
	# 1. Gerenciar a direção (Flip)
	# Se estiver se movendo para os lados, atualiza o flip
	if player.velocity.x != 0:
		flip_h = player.velocity.x < 0

	# 2. Lógica de Animação
	if not player.is_on_floor():
		# Estamos no ar
		if player.velocity.y < 0:
			play("jumping")
		else:
			play("falling")
	else:
		# Estamos no chão
		var horizontalSpeed = abs(player.velocity.x)
		
		if horizontalSpeed == 0:
			play("idle")
		elif horizontalSpeed > player.speed / 2:
			play("run")
		else:
			play("walk")

# Função para trocar o recurso visual
func _aplicar_sprite_frames(personagem: String):
	if personagem == "cryomancer":
		sprite_frames = cryomancerAnimation
	elif personagem == "assassin":
		sprite_frames = assassinAnimation
	
	# Opcional: Reinicia a animação idle após a troca
	play("idle")

# RPC para que os outros clientes vejam o personagem correto
@rpc("any_peer", "call_local", "reliable")
func _sincronizar_personagem(personagem: String):
	_aplicar_sprite_frames(personagem)
