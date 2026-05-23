extends Node2D

@onready var health_bar: Sprite2D = $Health
@onready var default_width: float = health_bar.region_rect.size.x
@onready var default_height: float = health_bar.region_rect.size.y

var max_health: float = 100.0

func _ready():
	await get_tree().process_frame
	determinar_vida_maxima_pelo_nome()

func determinar_vida_maxima_pelo_nome():
	var parent = get_parent()
	if parent == null:
		push_error("HealthBar: nó pai não encontrado.")
		return
	
	var parent_name = parent.name
	# Remove números do final do nome (ex: "Slime2" -> "Slime", "Goblin3" -> "Goblin")
	var clean_name = parent_name
	var regex = RegEx.new()
	regex.compile("\\d+$")  # Procura por um ou mais dígitos no final da string
	clean_name = regex.sub(clean_name, "", true)
	
	# Tenta buscar em EnemiesData
	if EnemiesData != null and EnemiesData.has_method("get_stats"):
		var stats = EnemiesData.get_stats(clean_name)
		if not stats.is_empty() and stats.has("health"):
			max_health = stats["health"]
			print("HealthBar: vida máxima encontrada em EnemiesData para '", clean_name, "': ", max_health)
			updateHealth(int(max_health))
			return
	
	# Tenta buscar em BossesData
	if BossesData != null and BossesData.has_method("get_stats"):
		var stats = BossesData.get_stats(clean_name)
		if not stats.is_empty() and stats.has("health"):
			max_health = stats["health"]
			print("HealthBar: vida máxima encontrada em BossesData para '", clean_name, "': ", max_health)
			updateHealth(int(max_health))
			return
	
	# Se não encontrou, usa padrão
	push_error("HealthBar: não foi possível encontrar vida máxima para '", clean_name, "'. Usando padrão: 100.0")
	max_health = 100.0
	updateHealth(int(max_health))

func updateHealth(new_health: int) -> void:
	if max_health <= 0:
		push_error("HealthBar: max_health inválido (", max_health, ")")
		return
	var new_width = (new_health / max_health) * default_width
	health_bar.region_rect = Rect2(0, 0, new_width, default_height)
