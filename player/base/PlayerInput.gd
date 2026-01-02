extends Node # Define que este objeto é um nó simples na árvore de cena

# Variáveis globais para armazenar o estado do input que será lido pelo script de movimento (Parent)
var movementDirection : float = 0.0  # Direção horizontal (-1.0 esquerda, 1.0 direita, 0 parado)
var jumpIntent : bool = false      # Estado do pulo (true se foi pressionado o botão de pular)
var jumpReleased : bool = false      # Estado do pulo (true se foi soltado o botão de pular)
var shiftPressed : bool = false      # Estado do shift (true se estiver pressionando o botão de shift)

# Função chamada a cada frame do jogo
func _process(_delta):
	# Se não houver conexão de rede OU se este script não for o "dono" (autoridade) deste player, interrompe aqui
	if multiplayer.multiplayer_peer == null or not get_parent().is_multiplayer_authority():
		return
	
	# Verifica qual nó da interface (UI) está com o foco do teclado no momento
	var focusOwner = get_viewport().gui_get_focus_owner()
	
	# --- Lógica de bloqueio enquanto o CHAT (LineEdit) está aberto ---
	if focusOwner is LineEdit:
		movementDirection = 0 # Zera o movimento para o player não andar sozinho enquanto digita
		jumpIntent = false    # Impede que o player pule enquanto digita
		
		# Verifica se o jogador apertou ESC (ui_cancel) especificamente para sair do chat
		if Input.is_action_just_pressed("ui_cancel"):
			focusOwner.release_focus() # Remove o foco do chat (fecha o teclado/cursor)
			
			get_viewport().set_input_as_handled() # Avisa o Godot que este ESC já foi "resolvido"
		
		return # Interrompe o script aqui para não processar os comandos de movimento abaixo

	# --- Movimentação normal (só ocorre se o chat estiver fechado) ---
	# Lê a diferença entre as teclas direita e esquerda e atribui um valor entre -1 e 1
	movementDirection = Input.get_axis("ui_left", "ui_right")
	
	# Verifica se a tecla configurada para "pular" (seta para cima/W) está sendo pressionada
	if Input.is_action_just_pressed("ui_up"):
		jumpIntent = true
		jumpReleased = false
	# Verifica se a tecla configurada para "pular" (seta para cima/W) está foi solta
	if Input.is_action_just_released("ui_up"):
		jumpReleased = true
	
	# Verifica se a tecla configurada para "shift" está sendo pressionada
	shiftPressed = Input.is_action_pressed("shift")

# Função para capturar inputs que a interface (UI) não consumiu
func _unhandled_input(event: InputEvent):
	# Garante que apenas o jogador local processe estes comandos globais
	if not get_parent().is_multiplayer_authority():
		return

	# --- ESC para o MENU ---
	# Se chegar aqui, o ESC não foi consumido pelo chat no _process acima, então abre o pause
	if event.is_action_pressed("ui_cancel"):
		_gerenciar_pause() # Chama a função que mostra/esconde o menu de pause
		
		get_viewport().set_input_as_handled() # Marca o evento como resolvido

	# --- ENTER (ui_accept) ---
	if event.is_action_pressed("ui_accept"):
		# Tenta encontrar o menu de pause na cena
		var pause_menu = get_tree().get_first_node_in_group("PauseMenu")
		
		# Se o menu de pause estiver visível, fecha ele antes de abrir o chat
		if pause_menu and pause_menu.visible:
			pause_menu.visible = false
		
		_gerenciar_foco_chat() # Chama a função que coloca o cursor no campo de texto
		
		get_viewport().set_input_as_handled() # Marca o evento como resolvido

# Função auxiliar para focar no campo de entrada do chat
func _gerenciar_foco_chat():
	# Busca o LineEdit do chat pelo grupo que configuramos
	var chat_input = get_tree().get_first_node_in_group("ChatInputGroup")
	
	# Se o chat existir e ainda não estiver focado, aplica o foco (abre para digitar)
	if chat_input and not chat_input.has_focus():
		chat_input.grab_focus()

# Função auxiliar para alternar a visibilidade do menu de pause
func _gerenciar_pause():
	# Busca o nó da interface de pause pelo grupo
	var pause_menu = get_tree().get_first_node_in_group("PauseMenu")
	
	# Se o menu existir, inverte o estado atual (se está visível, some; se está sumido, aparece)
	if pause_menu:
		pause_menu.visible = !pause_menu.visible
