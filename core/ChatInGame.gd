extends Node
# Script responsável por gerenciar o sistema de chat in-game.
# Sincroniza mensagens entre todos os jogadores via RPC.

@onready var chat_box = $ScrollContainer/ChatBox
# Removido "InterfaceChat/" do início, pois o script já está nesse nó

@onready var chat_input = $ChatInput
# Removido "InterfaceChat/" do início

func _ready():
	# Conecta o sinal de envio de texto apenas se o nó for encontrado
	if chat_input:
		chat_input.text_submitted.connect(_on_chat_input_submitted)

@rpc("any_peer", "call_local", "reliable")
func _receive_message(sender: String, message: String, color: Color):
	# Usamos RichTextLabel para permitir o uso de cores (BBCode)
	var label = RichTextLabel.new()
	
	# Ativa o BBCode para processar as tags de cor
	label.bbcode_enabled = true
	
	# Transforma a cor em código Hexadecimal (ex: #ff0000)
	var color_hex = color.to_html(false)
	
	# Formata a mensagem: [color=#hex]Nome[/color]: Mensagem
	label.text = "[color=#" + color_hex + "]" + sender + "[/color]: " + message
	
	# Configurações de layout (mesmas do Label anterior)
	label.fit_content = true # Faz o nó ajustar a altura ao texto
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	chat_box.add_child(label)
	
	# Scroll automático
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll_container = chat_box.get_parent() as ScrollContainer
	if scroll_container:
		var scroll_bar = scroll_container.get_v_scroll_bar()
		scroll_container.scroll_vertical = int(scroll_bar.max_value)

func _on_chat_input_submitted(new_text: String):
	if new_text.is_empty():
		chat_input.release_focus()
		return
	
	var sender_name = NetworkManager.local_nickname
	# PEGA A COR SALVA NO NETWORK MANAGER
	var sender_color = NetworkManager.local_player_color
	
	# ENVIA A COR JUNTO NO RPC
	rpc("_receive_message", sender_name, new_text, sender_color)
	
	chat_input.clear()
	chat_input.release_focus()
