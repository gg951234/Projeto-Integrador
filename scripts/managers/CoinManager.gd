extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: String = "res://assets/sounds/collectables/Coin.mp3"

# Chamado pelo GameManager quando a fase inicia
func spawn_coins(level_name: String) -> void:
	# Coleta todos os Marker2D que são filhos diretos (ou descendentes) deste nó
	var spawn_points = _collect_spawn_points(self)
	if spawn_points.is_empty():
		push_error("Nenhum ponto de spawn (Marker2D) encontrado em 'Enemies'")
		return

	# Obtém os inimigos para este nível
	var enemies_data = LevelEnemiesData.get_enemies_for_level(level_name)
	if enemies_data.is_empty():
		push_error("Nenhum dado de inimigo para o nível: ", level_name)
		return

	# Conta total de inimigos
	var total_enemies = 0
	for count in enemies_data.values():
		total_enemies += count

	if total_enemies > spawn_points.size():
		push_warning("Mais inimigos do que pontos de spawn; alguns spawns serão reutilizados.")

	# Embaralha os spawns para aleatoriedade
	spawn_points.shuffle()

	var spawn_index = 0
	for enemy_type in enemies_data:
		var count = enemies_data[enemy_type]
		var stats = EnemiesData.get_stats(enemy_type)
		if stats.is_empty():
			push_error("Tipo de inimigo desconhecido: ", enemy_type)
			continue

		var scene_path = stats["scene"]
		var scene = load(scene_path)
		if not scene:
			push_error("Falha ao carregar cena: ", scene_path)
			continue

		for i in range(count):
			# Seleciona spawn (índice cíclico se necessário)
			var spawn = spawn_points[spawn_index % spawn_points.size()]
			spawn_index += 1

			var enemy_instance = scene.instantiate()
			enemy_instance.name = "Slime" + str(spawn_index)
			enemy_instance.enemy_type = enemy_type   # Define o tipo antes de adicionar
			enemy_instance.global_position = spawn.global_position
			# Adiciona como filho deste nó "Enemies" (ou pode ser adicionado ao LevelRoot)
			add_child(enemy_instance)

# Função recursiva para coletar todos os Marker2D com nome começando com "Spawn"
func _collect_spawn_points(node: Node) -> Array:
	var result = []
	for child in node.get_children():
		if child is Marker2D and child.name.begins_with("Spawn"):
			result.append(child)
		elif child.get_child_count() > 0:
			result.append_array(_collect_spawn_points(child))
	return result

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collision_shape_2d.set_deferred("disabled", true)
		animated_sprite_2d.visible = false
		GameManager.add_coins()
		GameManager.add_score(10)
		AudioManager.tocar_sfx(position, audio_stream_player_2d)
		queue_free()
