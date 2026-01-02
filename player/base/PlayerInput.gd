extends Node
class_name PlayerInput
# Responsável por gerenciar e filtrar os inputs do player local

# ==============================================================================
# VARIÁVEIS DE ESTADO (Lidas pelo PlayerMovement)
# ==============================================================================
var movementDirection : float = 0.0  # Direção horizontal (-1.0 esquerda, 1.0 direita, 0 parado)
var jumpIntent : bool = false       # Estado do pulo (true se foi pressionado o botão de pular)
var jumpReleased : bool = false     # Estado do pulo (true se foi soltado o botão de pular)
var shiftPressed : bool = false     # Estado do shift (true se estiver pressionando o botão de shift)

# ==============================================================================
# LOOP DE PROCESSAMENTO
# ==============================================================================
func _process(_delta: float) -> void:
	# Se não houver conexão de rede OU se este script não for o "dono", interrompe aqui
	if multiplayer.multiplayer_peer == null or not get_parent().is_multiplayer_authority():
		return
	
	# Verifica qual nó da interface (UI) está com o foco do teclado no momento
	var focusOwner = get_viewport().gui_get_focus_owner()
	
	# --- Lógica de bloqueio enquanto o CHAT (LineEdit) está aberto ---
	if focusOwner is LineEdit:
		_handle_chat_input_block(focusOwner)
		return 

	# --- Processamento de Gameplay (Chat Fechado) ---
	_process_gameplay_input()

# ==============================================================================
# CAPTURA DE EVENTOS (UI e Menu)
# ==============================================================================
func _unhandled_input(event: InputEvent) -> void:
	# Garante que apenas o jogador local processe estes comandos globais
	if not get_parent().is_multiplayer_authority():
		return

	# --- ESC para o MENU ---
	if event.is_action_pressed("ui_cancel"):
		_gerenciar_pause()
		get_viewport().set_input_as_handled()

	# --- ENTER para o CHAT ---
	if event.is_action_pressed("ui_accept"):
		_handle_enter_press()
		get_viewport().set_input_as_handled()

# ==============================================================================
# MÉTODOS AUXILIARES E LÓGICA INTERNA
# ==============================================================================
func _process_gameplay_input() -> void:
	# Movimentação Horizontal
	movementDirection = Input.get_axis("ui_left", "ui_right")
	
	# Lógica de Pulo (Garante que o pulo variável e o buffer funcionem)
	if Input.is_action_just_pressed("ui_up"):
		jumpIntent = true
		jumpReleased = false
		
	if Input.is_action_just_released("ui_up"):
		jumpReleased = true
	
	# Shift (Caminhada Lenta)
	shiftPressed = Input.is_action_pressed("shift")

func _handle_chat_input_block(focusOwner: Control) -> void:
	movementDirection = 0.0 # Zera o movimento para o player não andar sozinho enquanto digita
	jumpIntent = false      # Impede que o player pule enquanto digita
	
	# Sai do chat ao apertar ESC
	if Input.is_action_just_pressed("ui_cancel"):
		focusOwner.release_focus()
		get_viewport().set_input_as_handled()

func _handle_enter_press() -> void:
	# Se o menu de pause estiver visível, fecha ele antes de abrir o chat
	var pauseMenu = get_tree().get_first_node_in_group("PauseMenu")
	if pauseMenu and pauseMenu.visible:
		pauseMenu.visible = false
	
	_gerenciar_foco_chat()

func _gerenciar_foco_chat() -> void:
	var chatInput = get_tree().get_first_node_in_group("ChatInputGroup")
	if chatInput and not chatInput.has_focus():
		chatInput.grab_focus()

func _gerenciar_pause() -> void:
	var pauseMenu = get_tree().get_first_node_in_group("PauseMenu")
	if pauseMenu:
		pauseMenu.visible = !pauseMenu.visible
