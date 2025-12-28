extends Control
# Cena de interface do lobby.
# Responsável por iniciar o servidor ou conectar a um servidor existente.

@export var ipInput: LineEdit
# Campo de texto onde o usuário digita o IP do host

@export var arena01: PackedScene
# Variável que representa o mapa "Arena01"

func _on_host_pressed():
	# Inicia o servidor localmente
	NetworkManager._start_server()
	
	# Troca para a cena da arena após criar o servidor
	get_tree().change_scene_to_packed(arena01)

func _on_join_pressed():
	# Inicia a conexão como cliente usando o IP digitado
	NetworkManager._start_client(ipInput.text)
	
	# Troca para a cena da arena após tentar conectar
	get_tree().change_scene_to_packed(arena01)
