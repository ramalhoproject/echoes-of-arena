extends Camera2D
# Script responsável exclusivamente pela câmera do player local

@export var smoothSpeed := 4
# Velocidade da suavização do movimento da câmera

func _ready():
	# Apenas o player local deve ativar a câmera
	var parentPlayer := get_parent()

	if not parentPlayer.is_multiplayer_authority():
		# Se não for o player local, desativa a câmera
		enabled = false
		return
	
	# Ativa a câmera do player local
	enabled = true
	make_current()
	
	# Ativa suavização nativa da Camera2D
	position_smoothing_enabled = true
	position_smoothing_speed = smoothSpeed
