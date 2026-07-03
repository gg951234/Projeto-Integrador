extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var coins_count: Label = $CoinsCount
@onready var enemies_defeated_count: Label = $EnemiesDefeatedCount
@onready var timer: Label = $Timer

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
	health_bar.value = new_health
	health_bar.max_value = max_health

func _update_coins(currentamount) -> void:
	coins_count.text = "Moedas: " + str(currentamount) + "/" + "5"

func _update_enemies_defeated(currentamount, maxamount) -> void:
	enemies_defeated_count.text = "Inimigos Derrotados: " + str(currentamount) + "/" + str(maxamount)
