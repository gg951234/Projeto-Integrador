class_name BossManager
extends CharacterBody2D

# Estados
enum State { MOVING, SKILL_ACTIVE }
var state: State = State.MOVING

# Estatísticas
var boss_type: String = ""
var speed: float
var health: int
var skill_pattern: Array
var skills: Dictionary
var current_pattern_index: int = 0

# Waypoints (agora fixos na cena, não mais filhos do boss)
var waypoints: Array[Marker2D] = []   # Lista de Marker2D encontrados no nó "Waypoints"
var current_waypoint: Marker2D = null

# Combate e sobrevivência
var isAlive: bool = true
var player: CharacterBody2D = null

# Timers
var skill_cooldown_timer: Timer

# Elementos de skill (podem ser usados pelos filhos)
var skill_markers: Array[Node2D] = []
var rock_scene: PackedScene = preload("res://scenes/rock.tscn")

# Referências visuais
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var health_bar: Node2D = $HealthBar

# ===== INICIALIZAÇÃO =====
func _ready():
	add_to_group("boss")
	load_stats()
	load_waypoints()
	setup_timers()
	find_player()
	start_patrol()

func load_stats():
	if boss_type.is_empty():
		push_error("BossManager: boss_type não foi definido.")
		return
	var data = BossesData.get_stats(boss_type)
	if data.is_empty():
		push_error("BossManager: dados não encontrados para ", boss_type)
		return
	
	speed = data["speed"]
	health = data["health"]
	skill_pattern = data["skill_pattern"]
	skills = data["skills"]
	
	health_bar.updateHealth(health)

func load_waypoints():
	# Aguarda um frame para garantir que toda a árvore de cena esteja pronta
	await get_tree().process_frame
	
	var waypoints_node = null
	
	# 1ª tentativa: procurar "Waypoints" em toda a árvore (a partir da raiz)
	waypoints_node = get_tree().root.find_child("Waypoints", true, false)
	
	# 2ª tentativa: se não achou, procurar dentro de um nó "LevelRoot" (se existir)
	if waypoints_node == null:
		var level_root = get_tree().root.find_child("LevelRoot", true, false)
		if level_root != null:
			waypoints_node = level_root.find_child("Waypoints", true, false)
	
	if waypoints_node == null:
		push_error("BossManager: Não foi encontrado um nó 'Waypoints' em toda a cena nem dentro de 'LevelRoot'. Adicione um Node2D chamado Waypoints com os Marker2D filhos.")
		return
	
	# Coleta todos os Marker2D filhos
	for child in waypoints_node.get_children():
		if child is Marker2D:
			waypoints.append(child)
	
	if waypoints.is_empty():
		push_error("BossManager: O nó 'Waypoints' não possui nenhum Marker2D como filho. Adicione pelo menos um Marker2D.")

func setup_timers():
	skill_cooldown_timer = Timer.new()
	skill_cooldown_timer.one_shot = true
	add_child(skill_cooldown_timer)
	skill_cooldown_timer.timeout.connect(_on_skill_cooldown_timeout)

func find_player():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("BossManager: player não encontrado (adicione ao grupo 'player')")

func start_patrol():
	# Aguarda um frame para garantir que toda a árvore de cena esteja pronta
	await get_tree().process_frame
	if waypoints.is_empty():
		push_error("BossManager: Nenhum waypoint disponível.")
		return
	choose_new_waypoint()
	state = State.MOVING

func choose_new_waypoint():
	if waypoints.size() == 0: return
	var new_waypoint = current_waypoint
	while new_waypoint == current_waypoint and waypoints.size() > 1:
		new_waypoint = waypoints[randi() % waypoints.size()]
	current_waypoint = new_waypoint
	current_target_pos = current_waypoint.global_position
	print("Next waypoint: ", current_waypoint.name)

# Variável auxiliar para o movimento
var current_target_pos: Vector2 = Vector2.ZERO

# ===== MOVIMENTO =====
func _physics_process(_delta: float):
	if not isAlive: return
	match state:
		State.MOVING:
			_move_to_target()
		State.SKILL_ACTIVE:
			velocity = Vector2.ZERO
	move_and_slide()

func _move_to_target():
	if current_target_pos == Vector2.ZERO:
		choose_new_waypoint()
		return
	var direction = (current_target_pos - position).normalized()
	velocity = direction * speed
	animated_sprite.play("move")
	
	if position.distance_to(current_target_pos) < 10.0:
		_on_arrived_at_waypoint()

func _on_arrived_at_waypoint():
	if state != State.MOVING: return
	velocity = Vector2.ZERO
	animated_sprite.play("idle")
	
	if skill_cooldown_timer.is_stopped() and skill_pattern.size() > 0:
		var skill_id = skill_pattern[current_pattern_index]
		current_pattern_index = (current_pattern_index + 1) % skill_pattern.size()
		_execute_skill(skill_id)
	else:
		choose_new_waypoint()

# ===== SISTEMA DE SKILLS =====
func _execute_skill(skill_id: int):
	state = State.SKILL_ACTIVE
	velocity = Vector2.ZERO
	animated_sprite.play("skill_" + str(skill_id))
	await animated_sprite.animation_finished
	
	match skill_id:
		1:
			await _skill_1()
		2:
			await _skill_2()
		3:
			await _skill_3()
		_:
			push_warning("Skill ", skill_id, " não implementada")
	
	var cooldown = skills[skill_id].get("cooldown", 3.0)
	skill_cooldown_timer.start(cooldown)
	state = State.MOVING
	choose_new_waypoint()

func _on_skill_cooldown_timeout():
	pass

# ===== MÉTODOS DE SKILL (sobrescrever nos filhos) =====
# Corrotinas: adicionamos um await inócuo para torná-las assíncronas.
func _skill_1() -> void:
	await get_tree().process_frame
	pass

func _skill_2() -> void:
	await get_tree().process_frame
	pass

func _skill_3() -> void:
	await get_tree().process_frame
	pass

# ===== DANO E MORTE =====
func take_damage(damage: int, _attackedpos: Vector2, _kbforce: int) -> void:
	health -= damage
	health_bar.updateHealth(health)
	if health <= 0:
		die()
		return
	hit_sound.play()
	var tween = create_tween()
	tween.tween_property(animated_sprite, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.1)

func die() -> void:
	isAlive = false
	state = State.SKILL_ACTIVE
	animated_sprite.play("die")
	hit_sound.pitch_scale = 0.7
	hit_sound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	skill_cooldown_timer.stop()
