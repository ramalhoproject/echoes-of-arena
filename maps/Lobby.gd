extends Control
# Cena de interface do lobby.

@export var nickName: LineEdit
@export var ipInput: LineEdit
@export var map: PackedScene
@export var connectionStatus: Label
@export var colorInput: ColorPickerButton

func _ready():
	# Conecta os sinais do multiplayer para reagir ao sucesso ou falha
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_fail)
	
	# Este sinal é disparado no CLIENTE quando o servidor cai
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# VERIFICAÇÃO DE MENSAGEM AO CARREGAR
	if NetworkManager.mensagemPendente != "":
		_notificar_player(NetworkManager.mensagemPendente, Color.DARK_ORANGE)
		# Limpa a mensagem para não aparecer de novo se o player resetar o lobby manualmente
		NetworkManager.mensagemPendente = ""
	
	# Seta o nickname já preenchido no último lobby
	nickName.text = NetworkManager.localNickname
	
	# Seta a cor já preenchida no último lobby
	colorInput.color = NetworkManager.localPlayerColor
	
	# Supondo que seus botões estão todos dentro de um nó chamado "WeatherContainer"
	var botoes = $SelecaoClima/WheaterButtons.get_children()
	
	for i in range(botoes.size()):
		var botao = botoes[i]
		# Conectamos o sinal 'pressed' e usamos o .bind(i) para enviar o índice do loop
		botao.pressed.connect(_on_clima_selecionado.bind(i))

func _on_host_pressed():
	if nickName.text.is_empty():
		_notificar_player("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
	
	# Salva o nick e inicia servidor
	NetworkManager.localNickname = nickName.text
	NetworkManager._start_server()
	
	# Como host é o servidor, ele pode mudar de cena na hora
	get_tree().change_scene_to_packed(map)

func _on_join_pressed():
	if nickName.text.is_empty():
		_notificar_player("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
		
	# Salva o nick, mas NÃO muda de cena ainda
	NetworkManager.localNickname = nickName.text
	NetworkManager._start_client(ipInput.text)
	
	# Feedback visual (opcional)
	connectionStatus.text = "Conectando..."
	connectionStatus.modulate = Color.GREEN
	nickName.editable = true

func _on_connection_success():
	get_tree().change_scene_to_packed(map)

func _on_connection_fail():
	# Se não encontrar o host, reativa os botões e avisa
	connectionStatus.text = "Falha ao conectar"

func _notificar_player(message: String, color: Color):
	connectionStatus.text = message
	connectionStatus.modulate = color

func _on_server_disconnected():
	# Resetamos a rede e voltamos ao lobby
	NetworkManager._reset_network("O Servidor caiu ou foi fechado")

func _on_cryomancer_button_pressed() -> void:
	NetworkManager.selectedCharacter = "cryomancer"
	_notificar_player("Cryomancer selecionado", Color.AQUA)

func _on_assassin_button_pressed() -> void:
	NetworkManager.selectedCharacter = "assassin"
	_notificar_player("Assassin selecionado", Color.BLACK)

func _on_clima_selecionado(clima_id: int):
	NetworkManager.backgroundEscolhido = clima_id
	_notificar_player(str("Fundo ", clima_id + 1, " selecionado"), Color.CORNSILK)

func _on_color_picker_button_color_changed(color: Color) -> void:
	NetworkManager.localPlayerColor = color
