extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var coins_count: Label = $CoinsCount
@onready var enemies_defeated_count: Label = $EnemiesDefeatedCount
@onready var timer: Label = $Timer
@onready var path_indicator: Label = get_node_or_null("PathIndicator")

var player
var max_health

# --------------
# SETAR PLAYER
# --------------
func set_player(p) -> void:
	player = p
	if player:
		show()
		max_health = player.health
		player.health_changed.connect(_update_health)
		player.died.connect(hide)
		_update_health(player.health)

func _update_health(new_health) -> void:
	health_bar.max_value = max_health
	health_bar.min_value = 0
	health_bar.value = new_health

func _update_coins(currentamount) -> void:
	coins_count.text = "Moedas: " + str(currentamount) + "/" + "10"

func format_time_simple(seconds: int) -> String:
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

func _update_timer(currentamount) -> void:
	timer.text = format_time_simple(currentamount)

func _update_enemies_defeated(currentamount, maxamount) -> void:
	enemies_defeated_count.text = "Inimigos Derrotados: " + str(currentamount) + "/" + str(maxamount)

# --------------
# INDICADOR DO MENOR CAMINHO (teoria de grafos / AStar2D)
# --------------
# Mostra/esconde o indicador do menor caminho no HUD. Acionado pelo
# PathGuideManager quando a guia de caminhos é liberada (último inimigo morto).
func mostrar_indicador_caminho(v: bool) -> void:
	if path_indicator:
		path_indicator.visible = v

# Atualiza o indicador conforme o jogador está (ou não) sobre a rota mais curta.
func atualizar_indicador_caminho(no_caminho: bool) -> void:
	if not path_indicator:
		return
	if no_caminho:
		path_indicator.text = "Menor caminho: SIM ✓"
		path_indicator.add_theme_color_override("font_color", Color(0.3, 1.0, 0.45))
	else:
		path_indicator.text = "Menor caminho: fora"
		path_indicator.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
