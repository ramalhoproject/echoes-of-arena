extends Node2D
# Cena principal da arena.
# Responsável por gerenciar spawn e remoção de players no multiplayer.

var playerScene: PackedScene = preload("res://player/Player.tscn")
# Cena base do player que será instanciada para cada peer conectado.

@onready var playersContainer = $Players
# Nó pai que organiza todos os instanciados no jogo

@onready var playersSpawner = $PlayersSpawn
# Nó MultiPlayerSpawner que replica a criação de objetos na rede

@onready var spawnPointsContainer = $Spawnpoints
# Nó que contém todos os Marker2D usados como referência de posição

var pointsList = []
# Array que armazenará as referências dos pontos de spawn

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
		NetworkManager.player_names[1] = NetworkManager.local_nickname
		
		# Cria o player local do próprio host imediatamente
		_spawn_player(1)
	else:
		# Se for um cliente, envia um RPC para o servidor registrando seu nickname
		rpc_id(1, "_server_register_name", NetworkManager.local_nickname)

func _on_peer_connected(_id: int):
	# O servidor detecta a conexão, mas para clientes, esperamos o RPC de registro de nome.
	# Não realizamos o spawn aqui para evitar que o player nasça sem o nickname correto.
	pass

@rpc("any_peer", "reliable")
func _server_register_name(nick: String):
	# Função executada apenas no servidor para registrar o nome enviado pelo peer
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Armazena o nickname associado ao ID do remetente no NetworkManager
	NetworkManager.player_names[sender_id] = nick
	
	# Agora que o servidor conhece o nick, ele solicita o spawn do player
	_spawn_player(sender_id)
	
	# --- MENSAGEM DE CONEXÃO NO CHAT ---
	# O servidor avisa a todos que esse player entrou.
	# Vamos definir uma cor cinza ou branca para mensagens de sistema,
	# ou usar a cor que o player acabou de ganhar.
	var mensagem = "conectou-se"
	
	# Chamamos o RPC do chat (que deve estar no mesmo grupo ou acessível)
	var chat = get_tree().get_first_node_in_group("InterfaceChatGroup")
	if chat:
		chat.rpc("_receive_message", nick, mensagem, Color.GREEN, true)

func _spawn_player(id: int):
	# Função auxiliar do servidor para calcular posição e disparar o spawn
	if multiplayer.is_server():
		# Seleciona o ponto de spawn baseado na ordem de entrada
		var index = playersContainer.get_child_count() % pointsList.size()
		var spawnPos = pointsList[index].global_position
		
		# Recupera o nick do dicionário (ou usa um fallback se não encontrar)
		var nick = NetworkManager.player_names.get(id, "Player_" + str(id))
		
		# Dispara o spawn oficial através do MultiplayerSpawner
		playersSpawner.spawn({"id": id, "pos": spawnPos, "nick": nick})

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
		var nick = NetworkManager.player_names.get(id, "Player_" + str(id))
		
		# Avisa no chat que o player saiu
		var chat = get_tree().get_first_node_in_group("InterfaceChatGroup")
		if chat:
			chat.rpc("_receive_message", nick, "desconectou-se", Color.CORAL, true)
		
		# Limpa os dados
		NetworkManager.player_names.erase(id)
	
	if playersContainer.has_node(str(id)):
		playersContainer.get_node(str(id)).queue_free()

func _on_host_lost():
	# Feedback antes de resetar (opcional)
	NetworkManager._reset_network("Host desligou o servidor")
