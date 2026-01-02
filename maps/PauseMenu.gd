extends CanvasLayer
class_name PauseMenu
# Gerencia o menu de pause e a desconexão voluntária do jogador.

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	# Adiciona ao grupo para que o script PlayerInput possa localizar este nó
	add_to_group("PauseMenu")
	
	# Garante que o menu comece oculto
	hide()

# ==============================================================================
# SINAIS (UI)
# ==============================================================================
## Chamado quando o botão de sair é pressionado na interface
func _on_btn_sair_pressed() -> void:
	_voltar_ao_lobby()

# ==============================================================================
# MÉTODOS DE AÇÃO
# ==============================================================================
func _voltar_ao_lobby() -> void:
	# O NetworkManager._reset_network() é responsável por fechar a conexão,
	# limpar dicionários de players e carregar a cena do menu principal.
	NetworkManager._reset_network()
