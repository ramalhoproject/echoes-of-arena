extends Node2D
# Cena principal da arena.
# Responsável por gerenciar spawn e remoção de players no multiplayer.

@export var playerScene: PackedScene
# Cena base do player que será instanciada para cada peer conectado.

@onready var spawnpoint := $Spawnpoint
# Ponto inicial onde os players irão spawnar na arena.

func _ready():
	# Conecta os sinais de entrada e saída de peers no multiplayer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Se este peer for o servidor (host),
	# cria o player local do próprio host
	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())

func _on_peer_connected(id: int):
	# Chamado automaticamente quando um novo peer se conecta
	if multiplayer.is_server():
		print("Peer conectado:", id)
		# Apenas o servidor é responsável por criar os players
		_spawn_player(id)

func _on_peer_disconnected(id: int):
	# Chamado automaticamente quando um peer se desconecta
	if has_node(str(id)):
		print("Peer saiu:", id)
		# Remove o player correspondente ao peer que saiu
		get_node(str(id)).queue_free()

func _spawn_player(id: int):
	# Instancia a cena do player
	var player := playerScene.instantiate()
	
	# Define o nome como peer_id (ESSENCIAL)
	player.name = str(id)
	
	# Adiciona à cena
	add_child(player)
