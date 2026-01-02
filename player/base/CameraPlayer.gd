extends Camera2D
class_name PlayerCamera
# Script responsável exclusivamente pela câmera do player local

# ==============================================================================
# VARIÁVEIS EXPORT (@export)
# ==============================================================================
@export_group("Configurações de Suavização")
@export var smoothSpeed : float = 4.0
# Velocidade da suavização do movimento da câmera

# ==============================================================================
# CICLO DE VIDA
# ==============================================================================
func _ready() -> void:
	_setup_camera_authority()

# ==============================================================================
# LÓGICA DE CONFIGURAÇÃO
# ==============================================================================
func _setup_camera_authority() -> void:
	# Apenas o player que possui a autoridade (jogador local) deve ativar sua câmera
	var parentPlayer = get_parent()

	if not parentPlayer.is_multiplayer_authority():
		# Se não for o player local, desativa a câmera para não interferir na visão
		enabled = false
		return
	
	# Ativa e define como a câmera principal da cena para o jogador local
	enabled = true
	make_current()
	
	# Aplica as configurações de suavização nativa da Camera2D
	position_smoothing_enabled = true
	position_smoothing_speed = smoothSpeed
