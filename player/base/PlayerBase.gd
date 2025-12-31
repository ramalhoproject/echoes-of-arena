extends CharacterBody2D
class_name PlayerBase

# =========================
# COMPONENTES
# =========================
@export_category("Components")
@export var input_component: Node
@export var movement_component: Node
@export var visual_component: Node

# =========================
# STATUS
# =========================
@export_category("Stats")
@export var max_health: int = 100
var health: int = 100
var is_dead := false

# =========================
# NETWORK
# =========================
@export_category("Network")
@export var synchronizer: MultiplayerSynchronizer

# =========================
# DADOS DO PERSONAGEM
# =========================
var character_data

# =========================
# READY
# =========================
func _ready():
	# Multiplayer authority
	if not is_multiplayer_authority():
		if input_component:
			input_component.set_process(false)
		set_physics_process(false)
	
	health = max_health
	
	if visual_component:
		visual_component.setup(self)

# =========================
# PROCESSO DE MOVIMENTO
# =========================
func _physics_process(delta):
	if is_dead:
		return
	
	if movement_component:
		movement_component.process_movement(delta)

# =========================
# SETUP DE PERSONAGEM
# =========================
func setup_character(data):
	character_data = data
	
	max_health = data.max_health
	health = max_health
	
	if movement_component:
		movement_component.speed = data.move_speed
		movement_component.jump_force = data.jump_force
	
	if visual_component:
		visual_component.apply_visual(data)

# =========================
# VIDA / DANO
# =========================
func take_damage(amount: int):
	if is_dead:
		return
	
	health -= amount
	
	if visual_component:
		visual_component.play_hit()
	
	if health <= 0:
		die()

func die():
	is_dead = true
	health = 0
	
	if visual_component:
		visual_component.play_death()
	
	# Futuro: respawn ou fim de rodada

# =========================
# INTERFACE DE MOVIMENTO
# =========================
func set_direction(dir: Vector2):
	if movement_component:
		movement_component.set_direction(dir)

func jump():
	if movement_component:
		movement_component.jump()

func dash():
	if movement_component and movement_component.has_method("dash"):
		movement_component.dash()
