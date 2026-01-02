extends CharacterBody2D
class_name PlayerMovement
# Responsável por gerenciar toda movimentação do player

# ==============================================================================
# CONSTANTES DE GAMEPLAY
# ==============================================================================
const JUMP_GRAVITY : float = 1400.0
const FALL_GRAVITY : float = 1800.0

# ==============================================================================
# VARIÁVEIS EXPORT (@export)
# ==============================================================================
@export_group("Movimentação Horizontal")
@export var maxSpeed : float = 250.0
@export var timeToReachMaxSpeed : float = 0.1
var acceleration : float
@export var timeToReachZeroSpeed : float = 0.1
var deceleration : float

@export_group("Salto e Gravidade")
@export var jumpForce : float = 650.0
@export var jumpCutoffValue : float = 0.3
@export var terminalVelocity : float = 700.0
@export var descendingGravityFactor: float = 1.7
@export var canDoubleJump : bool = true
@export var maxJumps : int = 2
@export var coyoteTime : float = 0.2 ## coyoteTime: Permite pular mesmo após deixar a plataforma (ajuda no Game Feel)
@export var jumpBufferTime : float = 0.15 ## jumpBufferTime: Salva o input de pulo antes de tocar o chão para executá-lo ao pousar

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
var jumpsRemaining : int = 0 # Contador interno de pulos

@onready var rayLeft : RayCast2D = $HeadCollision/RayCastLeft
@onready var rayRight : RayCast2D = $HeadCollision/RayCastRight

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	acceleration = maxSpeed / timeToReachMaxSpeed
	deceleration = maxSpeed / timeToReachZeroSpeed

# ==============================================================================
# LOOP PRINCIPAL (Física)
# ==============================================================================
func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): 
		return
	
	_update_timers(delta)
	_handle_input_logic()
	_handle_movement(delta)
	_handle_jump(delta)
	_apply_gravity(delta)
	_handle_corner_correction()
	
	move_and_slide()

# ==============================================================================
# PROCESSAMENTO DE ESTADOS
# ==============================================================================
func _update_timers(delta: float) -> void:
	var wasCoyoteAvailable = coyoteTimer > 0.0
	
	coyoteTimer -= delta
	jumpBufferTimer -= delta
	
	if is_on_floor():
		coyoteTimer = coyoteTime
		jumpsRemaining = maxJumps
	else:
		# --- LÓGICA DE EXPIRAÇÃO DO COYOTE ---
		# Se o coyote estava disponível no frame anterior e agora acabou...
		if wasCoyoteAvailable and coyoteTimer <= 0.0:
			# Se o player ainda tem todos os pulos (ou seja, caiu e não pulou)
			if jumpsRemaining == maxJumps:
				# Ele perde o pulo "do chão", restando apenas os extras
				jumpsRemaining -= 1

func _handle_input_logic() -> void:
	# Verifica a intenção de pulo vinda do script de input
	if playerInput.jumpIntent:
		jumpBufferTimer = jumpBufferTime
		playerInput.jumpIntent = false

# ==============================================================================
# MÉTODOS DE MOVIMENTAÇÃO
# ==============================================================================
func _handle_movement(delta: float) -> void:
	var targetSpeed = maxSpeed
	
	if playerInput.shiftPressed: 
		targetSpeed /= 3.0
	
	var targetVelocityX = playerInput.movementDirection * targetSpeed
	
	if playerInput.movementDirection != 0:
		velocity.x = move_toward(velocity.x, targetVelocityX, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func _handle_jump(_delta: float) -> void:
	# Lógica de início de pulo (Buffer + Coyote)
	if jumpBufferTimer > 0.0 and coyoteTimer > 0.0:
		_execute_jump()
		# Ao pular do chão, removemos o pulo do chão e o pulo extra (se houver apenas 2)
		# Ou simplesmente decrementamos para manter a lógica de múltiplos pulos
		jumpsRemaining -= 1 
	# 2. SALTO ADICIONAL (Pulo Duplo no Ar)
	elif jumpBufferTimer > 0.0 and canDoubleJump and jumpsRemaining > 0:
		# Se estamos no ar e o coyote time acabou, mas ainda temos pulos restantes
		if not is_on_floor():
			_execute_jump()
			jumpsRemaining -= 1
	
	# Lógica de corte (Pulo Variável) - Mantém a mesma
	if playerInput.jumpReleased:
		if velocity.y < 0.0:
			velocity.y *= jumpCutoffValue
		
		playerInput.jumpReleased = false

## Função auxiliar para aplicar a força do pulo e resetar o buffer
func _execute_jump() -> void:
	velocity.y = -jumpForce
	jumpBufferTimer = 0.0
	coyoteTimer = 0.0 # Consome o coyote time ao pular

func _apply_gravity(delta: float) -> void:
	if is_on_floor(): 
		return
	
	var gravity = JUMP_GRAVITY if velocity.y < 0.0 else FALL_GRAVITY
	velocity.y += gravity * delta

# ==============================================================================
# CORREÇÃO DE COLISÃO
# ==============================================================================
func _handle_corner_correction() -> void:
	if velocity.y >= 0:
		return
	
	var leftHit = rayLeft.is_colliding()
	var rightHit = rayRight.is_colliding()
	
	if leftHit == rightHit: return
	
	var currentYVelocity = velocity.y
	
	if rightHit:
		# 1. Ponto X onde o raio atingiu a plataforma
		var collisionX = rayRight.get_collision_point().x
		
		# 2. Como o raio é vertical, o collisionX é a "nossa posição". 
		# Queremos saber onde a plataforma TERMINA à esquerda desse ponto.
		# Para isso, usamos o ponto de colisão e arredondamos para encontrar a borda do Tile.
		# Se seus tiles têm 32px, a quina estará em múltiplos de 32.
		
		var tileEdgeX = floor(collisionX / 32.0) * 32.0
		
		# 3. A distância que precisamos mover é a diferença entre a 
		# nossa borda direita (rayRight) e a quina da plataforma (tileEdgeX)
		var pushAmount = tileEdgeX - rayRight.global_position.x
		
		global_position.x += pushAmount - 0.1
		velocity.y = currentYVelocity
	elif leftHit:
		var collisionX = rayLeft.get_collision_point().x
		
		# Para o lado esquerdo, queremos a quina à DIREITA (ceil)
		var tileEdgeX = ceil(collisionX / 32.0) * 32.0
		
		var pushAmount = tileEdgeX - rayLeft.global_position.x
		
		global_position.x += pushAmount + 0.1
		velocity.y = currentYVelocity
