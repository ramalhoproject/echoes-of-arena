extends Control
# Cena de interface do lobby.

@export var ipInput: LineEdit
@export var nickName: LineEdit
@export var arena01: PackedScene
@export var connectionStatus: Label

func _ready():
	# Conecta os sinais do multiplayer para reagir ao sucesso ou falha
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_fail)
	
	# Este sinal é disparado no CLIENTE quando o servidor cai
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# VERIFICAÇÃO DE MENSAGEM AO CARREGAR
	if NetworkManager.mensagem_pendente != "":
		_notificar_erro(NetworkManager.mensagem_pendente, Color.DARK_ORANGE)
		# Limpa a mensagem para não aparecer de novo se o player resetar o lobby manualmente
		NetworkManager.mensagem_pendente = ""

func _on_host_pressed():
	if nickName.text.is_empty():
		_notificar_erro("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
	
	# Salva o nick e inicia servidor
	NetworkManager.local_nickname = nickName.text
	NetworkManager._start_server()
	
	# Como host é o servidor, ele pode mudar de cena na hora
	get_tree().change_scene_to_packed(arena01)

func _on_join_pressed():
	if nickName.text.is_empty():
		_notificar_erro("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
		
	# Salva o nick, mas NÃO muda de cena ainda
	NetworkManager.local_nickname = nickName.text
	NetworkManager._start_client(ipInput.text)
	
	# Feedback visual (opcional)
	connectionStatus.text = "Conectando..."
	connectionStatus.modulate = Color.GREEN
	nickName.editable = true

func _on_connection_success():
	# Só entramos na arena se o servidor respondeu!
	get_tree().change_scene_to_packed(arena01)

func _on_connection_fail():
	# Se não encontrar o host, reativa os botões e avisa
	connectionStatus.text = "Falha ao conectar"

func _notificar_erro(message: String, color: Color):
	connectionStatus.text = message
	connectionStatus.modulate = color

func _on_server_disconnected():
	# Resetamos a rede e voltamos ao lobby
	NetworkManager._reset_network("O Servidor caiu ou foi fechado")
