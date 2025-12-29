extends Node

var movementDirection := 0
var jumpPressed := false

func _process(_delta):
	if not get_parent().is_multiplayer_authority():
		return
	
	movementDirection = Input.get_axis("ui_left", "ui_right")
	jumpPressed = Input.is_action_pressed("ui_up")
