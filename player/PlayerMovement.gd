extends CharacterBody2D
# Script responsável pelo movimento do player.
# Executa apenas no peer que possui autoridade sobre este player.

@export var speed := 300
# Velocidade horizontal do player

@export var jumpForce := 550.0
# Força aplicada ao pulo

@export var gravity := 1200.0
# Valor da gravidade aplicada quando o player está no ar

@onready var sprite := $Sprite2D
# Referência ao sprite do player para controle visual

func _enter_tree():
	# Obtém o ID do player a partir do nome do node
	# O nome do node é definido como o peer_id no spawn
	var playerId = str(name).to_int()
	
	if playerId != 0:
		# Define a autoridade multiplayer deste player
		set_multiplayer_authority(playerId)
	
		# Garante que o MultiplayerSynchronizer use a mesma autoridade
		$MultiplayerSynchronizer.set_multiplayer_authority(playerId)

func _ready():
	# Se este player NÃO for controlado localmente,
	# desativa processamento físico e de input
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	# Define uma cor aleatória para o player local
	sprite.modulate = Color.from_hsv(randf(), 0.8, 0.9)

func _physics_process(delta):
	# Aplica gravidade quando o player não está no chão
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Captura input horizontal
	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	
	# Executa pulo se estiver no chão
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -jumpForce
	
	# Move o player respeitando colisões
	move_and_slide()
