extends CharacterBody2D

@export var speed := 300.0
@export var jump_force := 550.0
@export var gravity := 1200.0

@onready var sprite := $Sprite2D

func _enter_tree():
	var player_id = str(name).to_int()
	if player_id != 0:
		set_multiplayer_authority(player_id)
		$MultiplayerSynchronizer.set_multiplayer_authority(player_id)

func _ready():
	if not is_multiplayer_authority():
		set_physics_process(false)
		set_process_unhandled_input(false)
		return
	sprite.modulate = Color.from_hsv(randf(), 0.8, 0.9)


func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed

	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = -jump_force

	move_and_slide()
