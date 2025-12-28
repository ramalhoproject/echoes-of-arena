extends Node

const port := 42069
const maxPlayers := 4

func _start_server():
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, maxPlayers)
	multiplayer.multiplayer_peer = peer
	print("Servidor criado na porta ", port)

func _start_client(ip: String):
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	print("Conectando ao servidor em ", ip, ":", port)
