extends Node
# Script responsável por gerenciar os inputs do jogador local.
# Controla movimentação, pulo e interação com o chat.

var movementDirection := 0  # Indica se o player move horizontalmente
var jumpPressed := false  # Indica se o player pula

func _process(_delta):
	# Verifica se este peer tem autoridade sobre o player para processar inputs
	if not get_parent().is_multiplayer_authority():
		return
	
	# Verifica se o usuário pressionou a tecla de confirmação (Enter por padrão)
	if Input.is_action_just_pressed("chat_open"):
		_gerenciar_foco_chat()
	
	# Se algum campo de texto estiver com o foco, ignora o input de movimento
	if get_viewport().gui_get_focus_owner() is LineEdit:
		# Reseta direções para o player não ficar "travado" andando ao abrir o chat
		movementDirection = 0
		jumpPressed = false
		return
	
	# Armazena a leitura dos inputs direita e esquerda em um range float de -1 a 1
	movementDirection = Input.get_axis("ui_left", "ui_right")
	
	# Indica com true ou false se o player está pressionando o input de pulo
	jumpPressed = Input.is_action_pressed("ui_up")

func _gerenciar_foco_chat():
	# Tenta encontrar o campo de entrada do chat na cena atual
	# Procura por um nó chamado "ChatInput" dentro do grupo "InterfaceChat" (recomendado)
	var chat_input = get_tree().get_first_node_in_group("ChatInputGroup")
	
	if chat_input:
		# Se o chat JÁ TEM o foco, não fazemos nada aqui.
		# O sinal 'text_submitted' do próprio LineEdit cuidará de dar o release_focus.
		if chat_input.has_focus():
			return
		
		# Se o chat NÃO tem o foco, aí sim nós o focamos.
		chat_input.grab_focus()
