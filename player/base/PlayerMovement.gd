extends CharacterBody2D
class_name PlayerMovement
# Responsável por gerenciar toda movimentação do player

# ==============================================================================
# CONSTANTES DE GAMEPLAY
# ==============================================================================
const JUMP_GRAVITY : float = 1400.0
const FALL_GRAVITY : float = 1800.0

## COYOTE_TIME: Permite pular mesmo após deixar a plataforma (ajuda no Game Feel)
const COYOTE_TIME : float = 2.0 

## JUMP_BUFFER_TIME: Salva o input de pulo antes de tocar o chão para executá-lo ao pousar
const JUMP_BUFFER_TIME : float = 0.15

# ==============================================================================
# VARIÁVEIS EXPORT (@export)
# ==============================================================================
@export_group("Movimentação Horizontal")
@export var speed : float = 250.0
@export var acceleration : float = 2400.0
@export var friction : float = 1800.0

@export_group("Salto")
@export var jumpForce : float = 600.0
@export var jumpCutoffValue : float = 0.3 

@export_group("Configurações de Colisão")
@export var headShiftAmount : float = 10.0
@export var headShiftSpeed : float = 30.0

@export_group("Referências")
@export var playerInput : Node2D 

# ==============================================================================
# VARIÁVEIS DE ESTADO E NÓS
# ==============================================================================
var coyoteTimer : float = 0.0
var jumpBufferTimer : float = 0.0

@onready var rayLeft : RayCast2D = $HeadCollision/RayCastLeft
@onready var rayRight : RayCast2D = $HeadCollision/RayCastRight

# ==============================================================================
# LOOP PRINCIPAL (Física)
# ==============================================================================
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): 
		return

	_updateTimers(delta)
	_handleInputLogic()
	
	_handleMovement(delta)
	_handleJump(delta)
	_applyGravity(delta)
	_handleCornerCorrection()
	
	move_and_slide()

# ==============================================================================
# PROCESSAMENTO DE ESTADOS
# ==============================================================================
func _updateTimers(delta: float) -> void:
	coyoteTimer -= delta
	jumpBufferTimer -= delta

	if is_on_floor():
		coyoteTimer = COYOTE_TIME

func _handleInputLogic() -> void:
	# Verifica a intenção de pulo vinda do script de input
	if playerInput.jumpIntent:
		jumpBufferTimer = JUMP_BUFFER_TIME
		playerInput.jumpIntent = false

# ==============================================================================
# MÉTODOS DE MOVIMENTAÇÃO
# ==============================================================================
func _handleMovement(delta: float) -> void:
	var targetSpeed = speed
	
	if playerInput.shiftPressed: 
		targetSpeed /= 3.0
	
	var targetVelocityX = playerInput.movementDirection * targetSpeed
	
	if playerInput.movementDirection != 0:
		velocity.x = move_toward(velocity.x, targetVelocityX, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

func _handleJump(_delta: float) -> void:
	# Lógica de início de pulo (Buffer + Coyote)
	if jumpBufferTimer > 0.0 and coyoteTimer > 0.0:
		velocity.y = -jumpForce
		jumpBufferTimer = 0.0
		coyoteTimer = 0.0
		
		if playerInput.jumpReleased:
			velocity.y *= jumpCutoffValue
			playerInput.jumpReleased = false

	# Lógica de corte (Pulo Variável)
	if playerInput.jumpReleased:
		if velocity.y < 0.0:
			velocity.y *= jumpCutoffValue
		
		playerInput.jumpReleased = false

func _applyGravity(delta: float) -> void:
	if is_on_floor(): 
		return
	
	var gravity = JUMP_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y += gravity * delta

# ==============================================================================
# CORREÇÃO DE COLISÃO
# ==============================================================================
func _handleCornerCorrection() -> void:
	if velocity.y >= 0:
		return
	
	var leftHit = rayLeft.is_colliding()
	var rightHit = rayRight.is_colliding()
	
	if rightHit and not leftHit:
		global_position.x -= headShiftAmount
		velocity.x = -headShiftSpeed
	elif leftHit and not rightHit:
		global_position.x += headShiftAmount
		velocity.x = headShiftSpeed
