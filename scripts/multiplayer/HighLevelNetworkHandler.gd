extends Node

const PORT := 42069
const MAX_PLAYERS := 4

func start_server():
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	print("Servidor criado na porta ", PORT)

func start_client(ip: String):
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, PORT)
	multiplayer.multiplayer_peer = peer
	print("Conectando ao servidor em ", ip, ":", PORT)
