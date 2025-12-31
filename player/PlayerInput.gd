extends Node

var movementDirection := 0  # Indica se o player move horizontalmente
var jumpPressed := false  # Indica se o player pula

func _process(_delta):
	if not get_parent().is_multiplayer_authority():
		return
	
	movementDirection = Input.get_axis("ui_left", "ui_right")
	# Armazena a leitura dos inputs direita e esquerda em um range float de -1 a 1
	
	jumpPressed = Input.is_action_pressed("ui_up")
	# Indica com true ou false se o player está pressionando o input de pulo
