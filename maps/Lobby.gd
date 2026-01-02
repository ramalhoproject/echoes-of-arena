extends Control
class_name LobbyMenu
# Gerencia a interface inicial, conexões multiplayer e customização do player.

# ==============================================================================
# VARIÁVEIS EXPORT (@export)
# ==============================================================================
@export_group("Referências de UI")
@export var nickName : LineEdit
@export var ipInput : LineEdit
@export var connectionStatus : Label
@export var colorInput : ColorPickerButton

@export_group("Configurações de Mapa")
@export var map : PackedScene

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	_setup_network_signals()
	_load_stored_preferences()
	_setup_weather_buttons()
	_check_pending_messages()

# ==============================================================================
# LÓGICA DE CONEXÃO
# ==============================================================================
func _on_host_pressed() -> void:
	if nickName.text.is_empty():
		_notificar_player("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
	
	# Salva preferências e inicia como Servidor
	NetworkManager.localNickname = nickName.text
	NetworkManager._start_server()
	
	# O Host avança diretamente para o mapa
	get_tree().change_scene_to_packed(map)

func _on_join_pressed() -> void:
	if nickName.text.is_empty():
		_notificar_player("Digite seu nickname", Color.RED)
		nickName.grab_focus()
		return
		
	# Salva preferências e tenta conectar ao IP informado
	NetworkManager.localNickname = nickName.text
	NetworkManager._start_client(ipInput.text)
	
	_notificar_player("Conectando...", Color.GREEN)

# ==============================================================================
# CUSTOMIZAÇÃO E SELEÇÃO
# ==============================================================================
func _on_cryomancer_button_pressed() -> void:
	NetworkManager.selectedCharacter = "cryomancer"
	_notificar_player("Cryomancer selecionado", Color.AQUA)

func _on_assassin_button_pressed() -> void:
	NetworkManager.selectedCharacter = "assassin"
	_notificar_player("Assassin selecionado", Color.BLACK)

func _on_color_picker_button_color_changed(color: Color) -> void:
	NetworkManager.localPlayerColor = color

func _on_clima_selecionado(climaId: int) -> void:
	NetworkManager.backgroundEscolhido = climaId
	_notificar_player(str("Fundo ", climaId + 1, " selecionado"), Color.CORNSILK)

# ==============================================================================
# RESPOSTAS DE REDE (SINAIS)
# ==============================================================================
func _on_connection_success() -> void:
	get_tree().change_scene_to_packed(map)

func _on_connection_fail() -> void:
	_notificar_player("Falha ao conectar", Color.RED)

func _on_server_disconnected() -> void:
	NetworkManager._reset_network("O Servidor caiu ou foi fechado")

# ==============================================================================
# MÉTODOS AUXILIARES
# ==============================================================================
func _setup_network_signals() -> void:
	multiplayer.connected_to_server.connect(_on_connection_success)
	multiplayer.connection_failed.connect(_on_connection_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _load_stored_preferences() -> void:
	nickName.text = NetworkManager.localNickname
	colorInput.color = NetworkManager.localPlayerColor

func _setup_weather_buttons() -> void:
	# Itera sobre os botões de clima para conectar o sinal 'pressed' dinamicamente
	var botoes = $SelecaoClima/WheaterButtons.get_children()
	for i in range(botoes.size()):
		botoes[i].pressed.connect(_on_clima_selecionado.bind(i))

func _check_pending_messages() -> void:
	if NetworkManager.mensagemPendente != "":
		_notificar_player(NetworkManager.mensagemPendente, Color.DARK_ORANGE)
		NetworkManager.mensagemPendente = ""

func _notificar_player(message: String, color: Color) -> void:
	connectionStatus.text = message
	connectionStatus.modulate = color
