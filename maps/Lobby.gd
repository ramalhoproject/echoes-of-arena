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

func _on_host_pressed():
	if nickName.text.is_empty():
		_notificar_erro_nick()
		return
	
	# Salva o nick e inicia servidor
	NetworkManager.local_nickname = nickName.text
	NetworkManager._start_server()
	
	# Como host é o servidor, ele pode mudar de cena na hora
	get_tree().change_scene_to_packed(arena01)

func _on_join_pressed():
	if nickName.text.is_empty():
		_notificar_erro_nick()
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
	nickName.editable = false
	nickName.text = ""
	connectionStatus.text = "Falha ao conectar!"

func _notificar_erro_nick():
	connectionStatus.text = "Digite seu nickname"
	connectionStatus.modulate = Color.RED
	nickName.grab_focus()
