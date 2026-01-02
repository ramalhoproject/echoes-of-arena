extends Node2D
# Cena principal da arena.
# Responsável por gerenciar spawn e remoção de players no multiplayer.

var playerScene: PackedScene = preload("res://player/base/Player.tscn")
# Cena base do player que será instanciada para cada peer conectado.

@onready var playersContainer = $Players
# Nó pai que organiza todos os instanciados no jogo

@onready var playersSpawner = $PlayersSpawn
# Nó MultiPlayerSpawner que replica a criação de objetos na rede

@onready var spawnPointsContainer = $Spawnpoints
# Nó que contém todos os Marker2D usados como referência de posição

var pointsList = []
# Array que armazenará as referências dos pontos de spawn

# Arraste suas 6 texturas para este Array no Inspetor do Godot
@onready var background : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/1.png"),
	preload("res://assets/clouds/clouds 2/1.png"),
	preload("res://assets/clouds/clouds 3/1.png"),
	preload("res://assets/clouds/clouds 4/1.png"),
	preload("res://assets/clouds/clouds 5/1.png"),
	preload("res://assets/clouds/clouds 6/1.png")
]
# Referência ao Sprite que está dentro do seu Background
@onready var backgroundSprite = $Background/Background

@onready var backgroundsObjects : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/2.png"),
	preload("res://assets/clouds/clouds 2/2.png"),
	preload("res://assets/clouds/clouds 3/2.png"),
	preload("res://assets/clouds/clouds 4/2.png"),
	preload("res://assets/clouds/clouds 5/2.png"),
	preload("res://assets/clouds/clouds 6/2.png")
]
@onready var backgroundObjectsSprite = $Background/BgObjects

@onready var backgroundCloudsFar : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/3.png"),
	preload("res://assets/clouds/clouds 2/3.png"),
	preload("res://assets/clouds/clouds 3/3.png"),
	preload("res://assets/clouds/clouds 4/3.png"),
	preload("res://assets/clouds/clouds 5/3.png"),
	preload("res://assets/clouds/clouds 6/3.png")
]
@onready var backgroundCloudsFarSprite = $BgCloudsFar/CloudsFar

@onready var backgroundCloudsClose : Array[Texture2D] = [
	preload("res://assets/clouds/clouds 1/4.png"),
	preload("res://assets/clouds/clouds 2/4.png"),
	preload("res://assets/clouds/clouds 3/4.png"),
	preload("res://assets/clouds/clouds 4/4.png"),
	preload("res://assets/clouds/clouds 5/4.png"),
	preload("res://assets/clouds/clouds 6/4.png")
]
@onready var backgroundCloudsCloseSprite = $BgCloudsClose/CloudsClose

func _ready():
	# Inicializa o gerador de números aleatórios com uma semente nova
	randomize()
	
	# Coleta todos os nós filhos do container de spawn
	pointsList = spawnPointsContainer.get_children()
	
	# Embaralha a lista uma única vez para garantir posições aleatórias mas fixas por partida
	pointsList.shuffle()
	
	# Define a lógica personalizada de criação de nós para o spawner
	playersSpawner.spawn_function = _custom_spawn
	
	# Conecta o sinal emitido quando um novo cliente entra na sessão
	multiplayer.peer_connected.connect(_on_peer_connected)
	
	# Conecta o sinal emitido quando um cliente sai da sessão
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Caso o cliente perca a conexão enquanto está na Arena
	multiplayer.server_disconnected.connect(_on_host_lost)
	
	# Verifica se a instância atual é o servidor
	if multiplayer.is_server():
		# O Host registra seu próprio nome no dicionário do servidor
		NetworkManager.playerNames[1] = NetworkManager.localNickname
		
		# Cria o player local do próprio host imediatamente
		_spawn_player(1, NetworkManager.localPlayerColor)
	else:
		# Se for um cliente, envia um RPC para o servidor registrando seu nickname
		rpc_id(1, "_server_register_name", NetworkManager.localNickname, NetworkManager.localPlayerColor)
	
	# Como essa função roda assim que a cena carrega, 
	# ela vai checar o que foi salvo no NetworkManager
	_configurar_background_local()

func _on_peer_connected(_id: int):
	# O servidor detecta a conexão, mas para clientes, esperamos o RPC de registro de nome.
	# Não realizamos o spawn aqui para evitar que o player nasça sem o nickname correto.
	pass

@rpc("any_peer", "reliable")
func _server_register_name(nick: String, color: Color):
	var senderId = multiplayer.get_remote_sender_id()
	NetworkManager.playerNames[senderId] = nick
	# Você pode criar um dicionário de cores no NetworkManager se quiser guardar
	
	_spawn_player(senderId, color) # Passa a cor recebida
	
	# Notifica o chat com a cor correta do player que entrou
	var chat = get_tree().get_first_node_in_group("InterfaceChatGroup")
	if chat:
		chat.rpc("_receive_message", nick, "conectou-se", color, true)

func _spawn_player(id: int, color: Color = Color.WHITE):
	# Função auxiliar do servidor para calcular posição e disparar o spawn
	if multiplayer.is_server():
			var index = playersContainer.get_child_count() % pointsList.size()
			var spawnPos = pointsList[index].global_position
			var nick = NetworkManager.playerNames.get(id, "Player_" + str(id))
			
			# Agora passamos a cor correta do player, não a do Host
			playersSpawner.spawn({"id": id, "pos": spawnPos, "nick": nick, "color": color})

func _custom_spawn(data: Variant) -> Node:
	# Esta função é executada em TODOS os peers (host e clientes) via MultiplayerSpawner
	var player = playerScene.instantiate()
	
	# Define o nome do nó como o ID para manter a sincronia entre os peers
	player.name = str(data.id)
	
	# Define a posição recebida através do dicionário de dados
	player.global_position = data.pos
	
	# Acessa o nó de identidade visual e aplica os dados de Nick e Cor
	# Certifique-se que o nó "PlayerVisual" existe dentro da cena Player.tscn
	player.get_node("PlayerVisual").setup_identity(data)
	
	# Retorna o player para que o Godot o adicione automaticamente ao playersContainer
	return player

func _on_peer_disconnected(id: int):
	if multiplayer.is_server():
		# Pega o nome do player antes de apagar do dicionário
		var nick = NetworkManager.playerNames.get(id, "Player_" + str(id))
		
		# Avisa no chat que o player saiu
		var chat = get_tree().get_first_node_in_group("InterfaceChatGroup")
		if chat:
			chat.rpc("_receive_message", nick, "desconectou-se", Color.CORAL, true)
		
		# Limpa os dados
		NetworkManager.playerNames.erase(id)
	
	if playersContainer.has_node(str(id)):
		playersContainer.get_node(str(id)).queue_free()

func _on_host_lost():
	# Feedback antes de resetar (opcional)
	NetworkManager._reset_network("Host desligou o servidor")

func _configurar_background_local():
	var id = NetworkManager.backgroundEscolhido
	
	# Verifica se o ID é válido e se a textura existe no array
	if id >= 0 and id < background.size():
		backgroundSprite.texture = background[id]
		backgroundObjectsSprite.texture = backgroundsObjects[id]
		backgroundCloudsFarSprite.texture = backgroundCloudsFar[id]
		backgroundCloudsCloseSprite.texture = backgroundCloudsClose[id]
	else:
		print("Erro: Índice de background inválido!")
