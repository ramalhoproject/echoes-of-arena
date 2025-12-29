extends CharacterBody2D
# Script responsável pelo movimento do player.
# Executa apenas no peer que possui autoridade sobre este player.

@export var speed := 300 # Velocidade horizontal do player
@export var jumpForce := 550 # Força aplicada ao pulo
@export var gravity := 1200 # Valor da gravidade aplicada quando o player está no ar

func _enter_tree():
	# O nome do node é o peer_id (definido pelo servidor no spawn)
	var player_id := str(name).to_int()
	
	# Define a autoridade DO PLAYER
	set_multiplayer_authority(player_id)
	
	# Define a autoridade DO MULTIPLAYER SYNCHRONIZER
	$MultiplayerSynchronizer.set_multiplayer_authority(player_id)
	
	if is_multiplayer_authority():
		# Posiciona o player no spawnpoint da arena
		global_position = $"../Spawnpoint".global_position

func _ready():
	# Se este player NÃO for controlado localmente,
	# desativa processamento físico e de input
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process_unhandled_input(false)

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
