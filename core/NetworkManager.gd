extends Node
# NetworkManager: Singleton responsável por gerenciar a infraestrutura de rede.
# Centraliza a criação de peers, gerenciamento de conexões e persistência de dados entre cenas.

# ==============================================================================
# CONFIGURAÇÕES DE REDE (Constantes)
# ==============================================================================
const PORT : int = 42069
const MAX_PLAYERS : int = 4

# ==============================================================================
# DADOS DO JOGADOR LOCAL (Persistência)
# ==============================================================================
var localNickname : String = ""
var localPlayerColor : Color = Color.WHITE
var selectedCharacter : String = "cryomancer"

# ==============================================================================
# ESTADO DA PARTIDA E SINCRONIZAÇÃO
# ==============================================================================
var playerNames : Dictionary = {} # Estrutura: { peer_id: "nickname" }
var backgroundEscolhido : int = 0
var mensagemPendente : String = ""

# ==============================================================================
# INICIALIZAÇÃO DE CONEXÕES
# ==============================================================================
## Configura e inicia esta instância como o Servidor (Host)
func _start_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	
	# Cria o servidor na porta definida
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		push_error("Falha ao criar servidor: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer

## Configura e inicia esta instância como um Cliente (Peer)
func _start_client(ip: String) -> void:
	if ip.is_empty():
		ip = "127.0.0.1" # Localhost padrão caso venha vazio
		
	var peer = ENetMultiplayerPeer.new()
	
	# Tenta conectar ao IP e porta informados
	var error = peer.create_client(ip, PORT)
	if error != OK:
		push_error("Falha ao iniciar cliente: " + str(error))
		return
		
	multiplayer.multiplayer_peer = peer

# ==============================================================================
# GERENCIAMENTO DE SESSÃO
# ==============================================================================
## Finaliza a conexão, limpa dados temporários e retorna o jogador ao menu
func _reset_network(mensagem: String = "") -> void:
	# Encerra a interface de rede
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	multiplayer.multiplayer_peer = null
	
	# Limpeza de dados da sessão anterior
	playerNames.clear()
	mensagemPendente = mensagem
	
	# Retorno ao Lobby principal
	_ir_para_lobby()

# ==============================================================================
# MÉTODOS AUXILIARES
# ==============================================================================
func _ir_para_lobby() -> void:
	# Ajuste o caminho da cena conforme a estrutura do seu projeto
	var lobbyPath = "res://maps/Lobby.tscn"
	
	if FileAccess.file_exists(lobbyPath):
		get_tree().change_scene_to_file(lobbyPath)
	else:
		push_error("Caminho do Lobby não encontrado: " + lobbyPath)
