extends Node2D
# Cena principal da arena.
# Responsável por gerenciar spawn e remoção de players no multiplayer.

@export var playerScene: PackedScene
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
	
	# Verifica se a instância atual é o servidor para criar o player do host
	if multiplayer.is_server():
		# Chama manualmente a função de conexão para o ID 1 (servidor)
		_on_peer_connected(1)

func _on_peer_connected(id: int):
	# Executa a lógica de distribuição apenas no servidor
	if multiplayer.is_server():
		# Calcula o índice usando o resto da divisão para ciclar entre os pontos disponíveis
		var index = playersContainer.get_child_count() % pointsList.size()
		
		# Obtém a posição global do marcador sorteado na lista embaralhada
		var spawnPos = pointsList[index].global_position
		
		# Solicita ao spawner que crie o objeto em todos os clientes com os dados fornecidos
		playersSpawner.spawn({"id": id, "pos": spawnPos})

func _custom_spawn(data: Variant) -> Node:
	# Instancia a cena do jogador localmente
	var p = playerScene.instantiate()
	
	# Define o nome do nó como o ID do peer para facilitar a busca posterior
	p.name = str(data.id)
	
	# Define a posição inicial baseada nos dados enviados pelo servidor
	p.global_position = data.pos
	
	# Retorna o nó para que o MultiPlayerSpawner o adicione à árvore
	return p

func _on_peer_disconnected(id: int):
	# Verifica se o nó do jogador que saiu existe dentro do container
	if playersContainer.has_node(str(id)):
		# Remove o nó do jogador da memória e da cena com segurança
		playersContainer.get_node(str(id)).queue_free()
