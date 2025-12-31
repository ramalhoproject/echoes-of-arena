extends CanvasLayer
# Gerencia o menu de pause e a desconexão voluntária.

func _ready():
	# Adiciona ao grupo para o PlayerInput te encontrar
	add_to_group("PauseMenu")
	hide()

func _on_btn_sair_pressed():
	# O reset_network já limpa tudo e volta ao lobby
	NetworkManager._reset_network()
