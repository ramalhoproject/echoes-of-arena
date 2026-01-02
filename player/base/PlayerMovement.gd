extends CharacterBody2D
class_name PlayerMovement

## CONSTANTES DE GAMEPLAY
const JUMP_GRAVITY : float = 1400
const FALL_GRAVITY : float = 1800
const COYOTE_TIME : float = 0.15   # Tempo (segundos) para pular após cair da plataforma
const JUMP_BUFFER_TIME : float = 0.15 # Tempo (segundos) que o comando de pulo fica "salvo"

# VARIÁVEIS EXPORT
@export var speed := 250 
@export var jumpForce := 600 
@export var acceleration : float = 2400 # Aumentei um pouco para ser mais responsivo
@export var friction : float = 1800
@export var playerInput: Node2D
@export var headShiftAmount : float = 10.0
@export var headShiftSpeed : float = 30.0

# VARIÁVEIS DE ESTADO INTERNO
var coyoteTimer : float = 0.0
var jumpBufferTimer : float = 0.0
var jumpCutoffValue : float = 0.3

@onready var rayLeft: RayCast2D = $HeadCollision/RayCastLeft
@onready var rayRight: RayCast2D = $HeadCollision/RayCastRight

func _physics_process(delta):
	if not is_multiplayer_authority(): return

	# 1. ATUALIZAR TIMERS
	coyoteTimer -= delta
	jumpBufferTimer -= delta

	if is_on_floor():
		coyoteTimer = COYOTE_TIME # Reset do coyote ao tocar o chão

	if playerInput.jumpIntent:
		jumpBufferTimer = JUMP_BUFFER_TIME # Salva a intenção de pular
		playerInput.jumpIntent = false # Consome o input bruto

	# 2. PROCESSAR MOVIMENTO
	_handle_movement(delta)
	_handle_jump(delta)
	_apply_gravity(delta)
	_handle_corner_correction()
	
	move_and_slide()

func _handle_movement(delta: float) -> void:
	var targetSpeed = speed
	if playerInput.shiftPressed: targetSpeed /= 3
	
	var targetVelocity = playerInput.movementDirection * targetSpeed
	
	if playerInput.movementDirection != 0:
		velocity.x = move_toward(velocity.x, targetVelocity, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _handle_jump(_delta: float) -> void:
	# 1. LOGICA DE INICIO DO PULO (Buffer + Coyote)
	if jumpBufferTimer > 0 and coyoteTimer > 0:
		velocity.y = -jumpForce
		jumpBufferTimer = 0
		coyoteTimer = 0
		# Se o jogador já soltou o botão antes mesmo de pular (clique ultra rápido), 
		# aplicamos o corte imediatamente após o impulso inicial
		if playerInput.jumpReleased:
			velocity.y *= jumpCutoffValue
			playerInput.jumpReleased = false

	# 2. LOGICA DE CORTE DO PULO (Variable Jump Height)
	if playerInput.jumpReleased:
		if velocity.y < 0.0:
			# Só corta se estiver subindo. 
			# Se estiver caindo, apenas limpamos a intenção.
			velocity.y *= jumpCutoffValue
		
		# IMPORTANTE: Consumimos o input para ele não ficar cortando a velocidade 
		# em frames seguintes de queda.
		playerInput.jumpReleased = false

func _apply_gravity(delta: float) -> void:
	if is_on_floor(): return
	
	# Gravidade variável: cai mais rápido do que sobe (melhora o feeling)
	var gravity := JUMP_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y += gravity * delta

func _handle_corner_correction():
	if velocity.y >= 0:
		return
	
	var leftHit = rayLeft.is_colliding()
	var rightHit = rayRight.is_colliding()
	
	# Se apenas o lado direito bateu, empurramos para a esquerda
	if rightHit and not leftHit:
		global_position.x -= headShiftAmount
		velocity.x = -headShiftSpeed
	# Se apenas o lado esquerdo bateu, empurramos para a direita
	elif leftHit and not rightHit:
		global_position.x += headShiftAmount
		velocity.x = headShiftSpeed
