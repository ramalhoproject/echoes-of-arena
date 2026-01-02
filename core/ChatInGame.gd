extends Node
class_name PlayerChat
# Gerencia a interface de chat, opacidade dinâmica e sincronização de mensagens.

# ==============================================================================
# REFERÊNCIAS DE NÓS
# ==============================================================================
@onready var chatBox = $VBoxContainer/ScrollContainer/ChatBox
@onready var chatInput = $VBoxContainer/ChatInput
@onready var container = $VBoxContainer

# ==============================================================================
# CONFIGURAÇÕES VISUAIS
# ==============================================================================
var corFocado : Color = Color(1, 1, 1, 1)     # 100% visível
var corApagado : Color = Color(1, 1, 1, 0.3)  # 30% visível

# ==============================================================================
# CONTROLE DE ESTADO E ANIMAÇÃO
# ==============================================================================
var tempoRestanteVisivel : float = 0.0
var tween : Tween

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	add_to_group("InterfaceChatGroup")
	
	_setup_signals()
	
	# Inicializa o chat com opacidade baixa
	container.modulate = corApagado

func _process(delta: float) -> void:
	# Se o chat estiver em uso, mantém a visibilidade máxima
	if chatInput.has_focus():
		tempoRestanteVisivel = 3.0
		container.modulate = corFocado
		if tween: tween.kill()
		return

	# Decrementa o timer de visibilidade
	if tempoRestanteVisivel > 0:
		tempoRestanteVisivel -= delta
		if tempoRestanteVisivel <= 0:
			_iniciar_fade_out()

# ==============================================================================
# LÓGICA DE MENSAGENS E REDE
# ==============================================================================
## Função RPC executada em todos os peers para exibir mensagens
@rpc("any_peer", "call_local", "reliable")
func _receive_message(sender: String, message: String, color: Color, isSystem: bool = false) -> void:
	_limpar_mensagens_antigas()
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	var colorHex = color.to_html(false)
	
	# Proteção: valida se mensagens de sistema realmente vêm do servidor (ID 1)
	var finalIsSystem = isSystem
	if isSystem and multiplayer.get_remote_sender_id() != 1:
		finalIsSystem = false
	
	# Formatação BBCode
	if finalIsSystem:
		label.text = "[i][color=#%s]%s %s[/color][/i]" % [colorHex, sender, message]
	else:
		label.text = "[color=#%s]%s[/color]: %s" % [colorHex, sender, message]
	
	_configurar_label_layout(label)
	chatBox.add_child(label)
	
	_scroll_to_bottom()
	_mostrar_temporariamente()

func _on_chat_input_submitted(newText: String) -> void:
	if newText.is_empty():
		chatInput.release_focus()
		_iniciar_fade_out()
		return
	
	# Envia a mensagem para todos os peers via RPC
	rpc("_receive_message", NetworkManager.localNickname, newText, NetworkManager.localPlayerColor, false)
	
	chatInput.clear()
	chatInput.release_focus()

# ==============================================================================
# MÉTODOS AUXILIARES (UI E FEEDBACK)
# ==============================================================================
func _setup_signals() -> void:
	if chatInput:
		chatInput.text_submitted.connect(_on_chat_input_submitted)
		chatInput.focus_entered.connect(_on_chat_focus_entered)
		chatInput.focus_exited.connect(_on_chat_focus_exited)

func _iniciar_fade_out() -> void:
	if tween: tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(container, "modulate", corApagado, 1.0)

func _mostrar_temporariamente() -> void:
	tempoRestanteVisivel = 3.0 
	if tween: tween.kill()
	container.modulate = corFocado

func _limpar_mensagens_antigas() -> void:
	var limiteMaximo = 50
	if chatBox.get_child_count() >= limiteMaximo:
		chatBox.get_child(0).queue_free()

func _configurar_label_layout(label: RichTextLabel) -> void:
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _scroll_to_bottom() -> void:
	# Aguarda a atualização do layout para rolar o ScrollContainer
	await get_tree().process_frame
	await get_tree().process_frame
	
	var scrollContainer = chatBox.get_parent() as ScrollContainer
	if scrollContainer:
		var scrollBar = scrollContainer.get_v_scroll_bar()
		scrollContainer.scroll_vertical = int(scrollBar.max_value)

# ==============================================================================
# SINAIS DE FOCO
# ==============================================================================
func _on_chat_focus_entered() -> void:
	if tween: tween.kill()
	container.modulate = corFocado
	tempoRestanteVisivel = 3.0

func _on_chat_focus_exited() -> void:
	_mostrar_temporariamente()
