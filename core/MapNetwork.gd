extends Node2D
class_name MapNetwork

# ==============================================================================
# RECURSOS E CENAS
# ==============================================================================
@export_group("Configurações de Spawn")
@export var playerScene: PackedScene = preload("res://player/base/Player.tscn")

@export_group("Texturas de Background")
@export var backgroundList : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/1.png"),
	preload("res://assets/clouds/clouds 2/1.png"),
	preload("res://assets/clouds/clouds 3/1.png"),
	preload("res://assets/clouds/clouds 4/1.png"),
	preload("res://assets/clouds/clouds 5/1.png"),
	preload("res://assets/clouds/clouds 6/1.png")
]
@export var backgroundObjectsList : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/2.png"),
	preload("res://assets/clouds/clouds 2/2.png"),
	preload("res://assets/clouds/clouds 3/2.png"),
	preload("res://assets/clouds/clouds 4/2.png"),
	preload("res://assets/clouds/clouds 5/2.png"),
	preload("res://assets/clouds/clouds 6/2.png")
]
@export var cloudsFarList : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/3.png"),
	preload("res://assets/clouds/clouds 2/3.png"),
	preload("res://assets/clouds/clouds 3/3.png"),
	preload("res://assets/clouds/clouds 4/3.png"),
	preload("res://assets/clouds/clouds 5/3.png"),
	preload("res://assets/clouds/clouds 6/3.png")
]
@export var cloudsCloseList : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/4.png"),
	preload("res://assets/clouds/clouds 2/4.png"),
	preload("res://assets/clouds/clouds 3/4.png"),
	preload("res://assets/clouds/clouds 4/4.png"),
	preload("res://assets/clouds/clouds 5/4.png"),
	preload("res://assets/clouds/clouds 6/4.png")
]

# ==============================================================================
# REFERÊNCIAS DE NÓS
# ==============================================================================
@onready var playersContainer = $Players
@onready var playersSpawner = $PlayersSpawn
@onready var spawnPointsContainer = $Spawnpoints

@onready var backgroundSprite = $Background/Background
@onready var backgroundObjectsSprite = $Background/BgObjects
@onready var backgroundCloudsFarSprite = $BgCloudsFar/CloudsFar
@onready var backgroundCloudsCloseSprite = $BgCloudsClose/CloudsClose

# ==============================================================================
# VARIÁVEIS DE ESTADO
# ==============================================================================
var pointsList : Array = []

# ==============================================================================
# CICLO DE VIDA (Ready)
# ==============================================================================
func _ready() -> void:
	randomize()
	
	# Inicialização do sistema de Spawn
	pointsList = spawnPointsContainer.get_children()
	pointsList.shuffle()
	playersSpawner.spawn_function = _custom_spawn
	
	# Conexões de sinais de rede
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_host_lost)
	
	_initialize_match()
	_configurar_background_local()

# ==============================================================================
# LÓGICA DE REDE E REGISTRO
# ==============================================================================
func _initialize_match() -> void:
	if multiplayer.is_server():
		# Registro local do Host
		NetworkManager.playerNames[1] = NetworkManager.localNickname
		_spawn_player(1, NetworkManager.localPlayerColor, NetworkManager.selectedCharacter)
	else:
		# Solicitação de registro do Cliente para o Servidor
		rpc_id(1, "_server_register_name", NetworkManager.localNickname, NetworkManager.localPlayerColor, NetworkManager.selectedCharacter)

@rpc("any_peer", "reliable")
func _server_register_name(nick: String, color: Color, character: String) -> void:
	var senderId = multiplayer.get_remote_sender_id()
	NetworkManager.playerNames[senderId] = nick
	
	_spawn_player(senderId, color, character)
	_notify_chat_connection(nick, color, true)

# ==============================================================================
# SISTEMA DE SPAWN
# ==============================================================================
func _spawn_player(id: int, color: Color, character: String) -> void:
	if multiplayer.is_server():
		var index = playersContainer.get_child_count() % pointsList.size()
		var spawnPos = pointsList[index].global_position
		var nick = NetworkManager.playerNames.get(id, "Player_" + str(id))
		
		# Dispara a replicação para todos os peers via MultiplayerSpawner
		playersSpawner.spawn({
			"id": id, 
			"pos": spawnPos, 
			"nick": nick, 
			"color": color, 
			"char": character
		})

func _custom_spawn(data: Variant) -> Node:
	# Executado em todas as instâncias quando o servidor chama playersSpawner.spawn()
	var player = playerScene.instantiate()
	player.name = str(data.id)
	player.set_multiplayer_authority(data.id)
	player.global_position = data.pos
	
	# Inicializa visual e animações através dos dados recebidos
	player.get_node("PlayerVisual")._setup_identity(data)
	player.get_node("AnimatedSprite2D")._setup_visual(data.char)
	
	return player

# ==============================================================================
# SINAIS E EVENTOS
# ==============================================================================
func _on_peer_connected(_id: int) -> void:
	pass # Aguardando registro via RPC

func _on_peer_disconnected(id: int) -> void:
	if multiplayer.is_server():
		var nick = NetworkManager.playerNames.get(id, "Player_" + str(id))
		_notify_chat_connection(nick, Color.CORAL, false)
		NetworkManager.playerNames.erase(id)
	
	if playersContainer.has_node(str(id)):
		playersContainer.get_node(str(id)).queue_free()

func _on_host_lost() -> void:
	NetworkManager._reset_network("Host desligou o servidor")

# ==============================================================================
# AUXILIARES VISUAIS
# ==============================================================================
func _configurar_background_local() -> void:
	var id = NetworkManager.backgroundEscolhido
	
	if id >= 0 and id < backgroundList.size():
		backgroundSprite.texture = backgroundList[id]
		backgroundObjectsSprite.texture = backgroundObjectsList[id]
		backgroundCloudsFarSprite.texture = cloudsFarList[id]
		backgroundCloudsCloseSprite.texture = cloudsCloseList[id]
	else:
		push_error("Índice de background inválido!")

func _notify_chat_connection(nick: String, color: Color, isConnect: bool) -> void:
	var msg = "conectou-se" if isConnect else "desconectou-se"
	var chat = get_tree().get_first_node_in_group("InterfaceChatGroup")
	if chat:
		chat.rpc("_receive_message", nick, msg, color, true)
