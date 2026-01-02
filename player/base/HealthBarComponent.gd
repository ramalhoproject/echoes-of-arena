extends ProgressBar
class_name HealthBarComponent

@export var player : PlayerBase

func _ready():
	# Configurações iniciais visuais
	show_percentage = false # Oculta o texto se quiser
	
	if player:
		# Conecta o sinal do player à função de atualizar desta barra
		player.health_changed.connect(update_bar)
		
		# Configura os valores iniciais
		max_value = player.max_health
		value = player.health
	else:
		push_warning("HealthBar: PlayerBase não atribuído no inspector!")

# Essa função é chamada automaticamente quando o sinal é emitido
func update_bar(new_health: int, max_hp: int):
	# Dica Pro: Podemos usar Tween para a barra descer suavemente
	var tween = create_tween()
	
	# Anima a propriedade 'value' para o novo valor em 0.2 segundos
	tween.tween_property(self, "value", new_health, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Atualiza o max_value caso a vida máxima mude (buffs/level up)
	max_value = max_hp
