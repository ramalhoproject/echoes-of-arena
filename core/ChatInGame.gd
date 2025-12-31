extends Node # Define que este script gerencia um nó (o sistema de chat)

# Referências aos nós da UI usando caminhos relativos (definidas ao carregar a cena)
@onready var chatBox = $VBoxContainer/ScrollContainer/ChatBox # Onde as mensagens são empilhadas
@onready var chatInput = $VBoxContainer/ChatInput           # Onde o jogador digita
@onready var container = $VBoxContainer                    # O container pai para controlar a opacidade de tudo

# Definições de cores e transparência (Alpha)
var corFocado = Color(1, 1, 1, 1)     # Branco sólido (100% visível)
var corApagado = Color(1, 1, 1, 0.3)  # Branco transparente (30% visível)

# Variáveis de controle de tempo e animação
var tempoRestanteVisivel := 0.0       # Timer manual para controlar o "tempo de brilho" do chat
var tween: Tween                      # Objeto que gerencia a transição suave de opacidade

func _ready():
	# Adiciona este nó ao grupo para ser encontrado por outros scripts (como o Arena ou Player)
	add_to_group("InterfaceChatGroup")
	
	# Verifica se o campo de input existe e conecta os sinais necessários
	if chatInput:
		chatInput.text_submitted.connect(_on_chat_input_submitted) # Quando dá Enter para enviar
		chatInput.focus_entered.connect(_on_chat_focus_entered)     # Quando o jogador clica para digitar
		chatInput.focus_exited.connect(_on_chat_focus_exited)       # Quando o foco sai do chat (ESC ou enviou)
	
	# Inicializa o chat com a opacidade baixa (apagado)
	container.modulate = corApagado

func _process(delta):
	# Se o jogador estiver com o cursor no chat, mantém ele visível e reseta o timer
	if chatInput.has_focus():
		tempoRestanteVisivel = 3.0
		container.modulate = corFocado
		if tween: tween.kill() # Interrompe qualquer animação de sumiço que esteja ocorrendo
		return

	# Lógica do Timer manual: se o tempo for maior que zero, decrementa a cada frame
	if tempoRestanteVisivel > 0:
		tempoRestanteVisivel -= delta
		# Quando o timer chega a zero, chama a função para desbotar o chat
		if tempoRestanteVisivel <= 0:
			_iniciar_fade_out()

func _iniciar_fade_out():
	# Interrompe animações anteriores para evitar conflitos
	if tween: tween.kill()
	# Cria uma nova animação suave
	tween = get_tree().create_tween()
	# Transiciona a propriedade 'modulate' do container para 'corApagado' em 1 segundo
	tween.tween_property(container, "modulate", corApagado, 1.0)

func _mostrar_temporariamente():
	# Define que o chat deve ficar aceso por 3 segundos
	tempoRestanteVisivel = 3.0 
	if tween: tween.kill() # Para qualquer sumiço em andamento
	container.modulate = corFocado # Deixa o chat 100% visível instantaneamente

# Função RPC: executada em todos os jogadores para exibir a mensagem
@rpc("any_peer", "call_local", "reliable")
func _receive_message(sender: String, message: String, color: Color, isSystem: bool = false):
	# --- NOVO: LIMITE DE MENSAGENS ---
	var limite_maximo = 50 # Define quantas mensagens quer manter na tela
	if chatBox.get_child_count() >= limite_maximo:
		# Pega a primeira mensagem (a mais antiga) e a deleta
		var mensagem_antiga = chatBox.get_child(0)
		mensagem_antiga.queue_free() 
	# ---------------------------------
	
	# Cria um novo nó de texto rico para a mensagem
	var label = RichTextLabel.new()
	label.bbcode_enabled = true # Ativa suporte a cores e estilos (BBCode)
	var color_hex = color.to_html(false) # Converte a cor do player para formato Hexadecimal (HTML)
	
	# Segurança: verifica se a mensagem diz ser do sistema mas não veio do Servidor (ID 1)
	var finalIsSystem = isSystem
	if isSystem and multiplayer.get_remote_sender_id() != 1:
		finalIsSystem = false
	
	# Formata o texto: Itálico se for sistema, Nome: Mensagem se for player
	if finalIsSystem:
		label.text = "[i][color=#" + color_hex + "]" + sender + " " + message + "[/color][/i]"
	else:
		label.text = "[color=#" + color_hex + "]" + sender + "[/color]: " + message
	
	# Configurações para o texto se ajustar ao tamanho do chat
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Adiciona a mensagem na lista (ChatBox)
	chatBox.add_child(label)
	
	# Espera dois frames para garantir que o motor calculou o novo tamanho da lista
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Faz o scroll descer automaticamente para a última mensagem
	var scrollContainer = chatBox.get_parent() as ScrollContainer
	if scrollContainer:
		var scrollBar = scrollContainer.get_v_scroll_bar()
		scrollContainer.scroll_vertical = int(scrollBar.max_value)
	
	# Acende o chat para o jogador ver que chegou mensagem nova
	_mostrar_temporariamente()

# Função chamada quando o jogador local envia um texto
func _on_chat_input_submitted(newText: String):
	# Se o texto estiver vazio, apenas fecha o chat
	if newText.is_empty():
		chatInput.release_focus()
		_iniciar_fade_out()
		return
	
	# Pega os dados do jogador local salvos no NetworkManager
	var senderName = NetworkManager.local_nickname
	var senderColor = NetworkManager.local_player_color
	
	# Chama a função RPC em todos os jogadores (incluindo em si mesmo)
	rpc("_receive_message", senderName, newText, senderColor, false)
	
	# Limpa o campo de texto e remove o foco para voltar ao jogo
	chatInput.clear()
	chatInput.release_focus()

# Quando o jogador clica no chat para digitar
func _on_chat_focus_entered():
	if tween: tween.kill() # Para o fade out
	container.modulate = corFocado # Fica visível
	tempoRestanteVisivel = 3.0 # Reseta o timer

# Quando o jogador sai do chat (enviou ou cancelou)
func _on_chat_focus_exited():
	# Inicia o timer para o chat apagar após o tempo de leitura
	_mostrar_temporariamente()
