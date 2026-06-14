class_name BossManager
extends CharacterBody2D

# Estados
enum State { IDLE, SKILL_ACTIVE, DOWNED }
var state: State = State.IDLE

# Estatísticas comuns (carregadas do BossesData)
var boss_type: String = ""
var speed: float
var health: int
var max_health: int               # guarda a vida máxima
var skill_pattern: Array
var skills: Dictionary
var current_pattern_index: int = 0

# Combate e sobrevivência
var isAlive: bool = true
var player: CharacterBody2D = null

# Timers
var skill_cooldown_timer: Timer
var skill_trigger_timer: Timer

# Sistema de skills dinâmicas
var skill_executors: Dictionary = {}

# Ajuste visual
@export var horizontal_threshold: float = 160.0
@export var interact_radius: float = 80.0   # distância para interagir com o boss caído

# Referências visuais
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: String = "res://assets/sounds/enemies/SlimeDamaged.mp3"
@onready var health_bar: Node2D = $HealthBar

# Controle dos limiares de down
var downed_66_triggered: bool = false
var downed_33_triggered: bool = false
var current_down_threshold: int = 0   # 66 ou 33
var is_quiz_open: bool = false

# ===== INICIALIZAÇÃO =====
func _ready():
	add_to_group("boss")
	load_stats()
	setup_timers()
	find_player()
	setup_skill_trigger_timer()
	_update_facing()

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
	max_health = health                     # guarda o valor máximo
	skill_pattern = data["skill_pattern"]
	skills = data["skills"]
	
	health_bar.updateHealth(health)

func setup_timers():
	skill_cooldown_timer = Timer.new()
	skill_cooldown_timer.one_shot = true
	add_child(skill_cooldown_timer)
	skill_cooldown_timer.timeout.connect(_on_skill_cooldown_timeout)

func setup_skill_trigger_timer():
	skill_trigger_timer = Timer.new()
	skill_trigger_timer.wait_time = 0.5
	skill_trigger_timer.one_shot = false
	add_child(skill_trigger_timer)
	skill_trigger_timer.timeout.connect(_on_skill_trigger_timeout)
	skill_trigger_timer.start()

func find_player():
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_warning("BossManager: player não encontrado (adicione ao grupo 'player')")

# ===== ROTAÇÃO (IDLE) =====
func _update_facing():
	if not isAlive or state != State.IDLE:
		return
	if player == null:
		find_player()
	if player == null:
		return
	
	var delta = player.global_position - global_position
	
	if abs(delta.x) <= horizontal_threshold:
		animated_sprite.flip_h = false
		if delta.y > 0:
			if animated_sprite.animation != "idle_down":
				animated_sprite.play("idle_down")
		else:
			if animated_sprite.animation != "idle_up":
				animated_sprite.play("idle_up")
	else:
		animated_sprite.flip_h = (delta.x < 0)
		if animated_sprite.animation != "idle_side":
			animated_sprite.play("idle_side")

# ===== SISTEMA DE SKILLS =====
func _on_skill_trigger_timeout():
	if isAlive and state == State.IDLE and skill_cooldown_timer.is_stopped() and not skill_pattern.is_empty():
		_execute_next_skill()

func _execute_next_skill():
	var skill_id = skill_pattern[current_pattern_index]
	current_pattern_index = (current_pattern_index + 1) % skill_pattern.size()
	_execute_skill(skill_id)

func _execute_skill(skill_id: int):
	state = State.SKILL_ACTIVE
	velocity = Vector2.ZERO

	if skill_executors.has(skill_id):
		await skill_executors[skill_id].call()
	else:
		push_warning("Skill ", skill_id, " não registrada em skill_executors para o boss ", boss_type)
	
	var cooldown = skills[skill_id].get("cooldown", 3.0)
	skill_cooldown_timer.start(cooldown)
	state = State.IDLE
	_update_facing()

func _on_skill_cooldown_timeout():
	pass

# ===== DANO E LIMIARES =====
func take_damage(damage: int, _attackedpos: Vector2, _kbforce: int) -> void:
	if not isAlive or state == State.DOWNED:
		return   # não toma dano enquanto caído ou morto
	
	var old_health = health
	health -= damage
	health = clamp(health, 0, max_health)
	health_bar.updateHealth(health)
	
	if health <= 0:
		die()
		return
	
	AudioManager.tocar_sfx(position, hit_sound, {Volume = -20.0})
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.1)
	
	# Verifica cruzamento de limiares (do maior para o menor)
	var health_percent = float(health) / max_health * 100.0
	var old_percent = float(old_health) / max_health * 100.0
	
	if not downed_66_triggered and old_percent > 66.0 and health_percent <= 66.0:
		health = clamp(max_health*0.66, 0, max_health)
		enter_down(66)
	elif not downed_33_triggered and old_percent > 33.0 and health_percent <= 33.0:
		health = clamp(max_health*0.33, 0, max_health)
		enter_down(33)

func die() -> void:
	isAlive = false
	state = State.SKILL_ACTIVE
	animated_sprite.play("die")
	
	AudioManager.tocar_sfx(position, hit_sound, {Volume = -10.0, Pitch = 0.7})

	$CollisionShape2D.set_deferred("disabled", true)
	skill_cooldown_timer.stop()
	skill_trigger_timer.stop()

# ===== ESTADO DOWNED =====
func enter_down(threshold: int):
	state = State.DOWNED
	current_down_threshold = threshold
	animated_sprite.play("downed")
	skill_trigger_timer.stop()   # impede ataques enquanto caído
	velocity = Vector2.ZERO
	
	# Marca o limiar como acionado
	if threshold == 66:
		downed_66_triggered = true
	else:
		downed_33_triggered = true

func exit_down():
	state = State.IDLE
	skill_trigger_timer.start()
	_update_facing()

# ===== INTERAÇÃO E QUIZ =====
func _physics_process(_delta):
	if not isAlive:
		return
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_update_facing()
		State.SKILL_ACTIVE:
			velocity = Vector2.ZERO
		State.DOWNED:
			velocity = Vector2.ZERO
			# Verifica interação do jogador (Espaço) se quiz não estiver aberto
			if not is_quiz_open and player and Input.is_action_just_pressed("attack"):
				var dist = global_position.distance_to(player.global_position)
				if dist <= interact_radius:
					_open_quiz()
	move_and_slide()

func _open_quiz():
	is_quiz_open = true
	# Pausa o jogo (opcional)
	get_tree().paused = true
	
	# Instancia a cena do quiz (assumindo um caminho válido)
	var quiz_scene = preload("res://scenes/quiz_popup.tscn")
	var quiz_instance = quiz_scene.instantiate()
	add_child(quiz_instance)
	
	# Configura pergunta conforme o limiar atual
	var quiz_data = get_quiz_data_for_threshold(current_down_threshold)
	quiz_instance.setup(quiz_data.question, quiz_data.options, quiz_data.correct_index)
	
	# Aguarda o sinal de conclusão
	quiz_instance.quiz_finished.connect(_on_quiz_finished, CONNECT_ONE_SHOT)

func get_quiz_data_for_threshold(threshold: int) -> Dictionary:
	# Exemplo de perguntas – você pode carregar de um arquivo de dados
	if threshold == 66:
		return {
			"question": "Qual é a capital do Brasil?",
			"options": ["São Paulo", "Rio de Janeiro", "Brasília", "Salvador"],
			"correct_index": 2
		}
	else:  # threshold == 33
		return {
			"question": "Quantos planetas tem o sistema solar?",
			"options": ["7", "8", "9", "10"],
			"correct_index": 1
		}

func _on_quiz_finished(correct: bool):
	# Remove a tela de quiz
	for child in get_children():
		if child.name == "QuizPopup":
			child.queue_free()
	
	get_tree().paused = false
	is_quiz_open = false
	
	if correct:
		# Sai do estado DOWNED e volta a atacar normalmente
		exit_down()
	else:
		# Aplica penalidade conforme o limiar
		if current_down_threshold == 66:
			health = max_health
			health_bar.updateHealth(health)
			# Libera os dois limiares para poderem ser acionados novamente
			downed_66_triggered = false
			downed_33_triggered = false
		else:  # 33%
			health = int(max_health * 0.66)
			health_bar.updateHealth(health)
			# Libera apenas o limiar de 33% (o de 66% permanece usado)
			downed_33_triggered = false
			# Evita que o reset para 66% acione novamente o downed imediatamente
			# Se o limiar de 66% ainda não tivesse sido usado, marcamos como usado para não trigger agora
			if not downed_66_triggered and health >= max_health * 0.66:
				downed_66_triggered = true
		# Sai do estado DOWNED (volta ao IDLE)
		exit_down()
