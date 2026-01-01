extends AnimatedSprite2D

@onready var playerMovement: CharacterBody2D = $".."

func _ready():
	print(playerMovement)

func _process(_delta: float) -> void:
	if playerMovement.velocity.x < 0:
		flip_h = true
	elif playerMovement.velocity.x > 0:
		flip_h = false
