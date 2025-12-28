extends Node2D

@export var playerScene: PackedScene
@export var spawnpoint: Node2D

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("Peer conectado:", id)
		_spawn_player(id)

func _on_peer_disconnected(id: int):
	if has_node(str(id)):
		print("Peer saiu:", id)
		get_node(str(id)).queue_free()

func _spawn_player(id: int):
	var player := playerScene.instantiate()
	player.name = str(id)
	player.global_position = spawnpoint.global_position
	add_child(player)
