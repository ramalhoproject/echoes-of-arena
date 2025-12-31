extends Node
# Script responsável por gerenciar a criação de servidor e cliente multiplayer.
# Centraliza toda a lógica de rede do projeto.

const port := 42069
# Porta usada para comunicação multiplayer

const maxPlayers := 4
# Número máximo de jogadores permitidos no servidor

var local_nickname : String = ""
# Armazena o nome do jogador local para ser usado durante o spawn
var player_names : Dictionary = {} # Mapeia { id: "nome" }

var local_player_color : Color

var mensagem_pendente: String = ""

func _start_server():
	# Cria um novo peer ENet
	var peer := ENetMultiplayerPeer.new()
	
	# Inicializa o peer como servidor
	peer.create_server(port, maxPlayers)
	
	# Define este peer como o multiplayer ativo do jogo
	multiplayer.multiplayer_peer = peer

func _start_client(ip: String):
	# Cria um novo peer ENet
	var peer := ENetMultiplayerPeer.new()
	
	# Conecta ao servidor usando IP e porta informados
	peer.create_client(ip, port)
	
	# Define este peer como o multiplayer ativo do jogo
	multiplayer.multiplayer_peer = peer

func _reset_network(mensagem: String = ""):
	# Fecha a conexão atual
	multiplayer.multiplayer_peer = null
	
	# Limpa a lista de nomes para a próxima partida
	player_names.clear()
	
	# Guardamos a mensagem antes de mudar a cena
	mensagem_pendente = mensagem
	
	# Volta para a cena do Lobby (ajuste o caminho se necessário)
	get_tree().change_scene_to_file("res://maps/Lobby.tscn")
	
