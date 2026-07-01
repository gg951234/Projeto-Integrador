class_name BossManager
extends CharacterBody2D

# Estados
enum States { IDLE, SKILL_ACTIVE, DOWNED }
var currentstate: States = States.IDLE

# Estatísticas
var boss_type: String = ""
var speed: float
var health: int
var max_health: int
var skill_pattern: Array
var skills: Dictionary
var current_pattern_index: int = 0
var target = null

# Combate
var isAlive: bool = true
var player: CharacterBody2D = null

# Timers
var skill_cooldown_timer: Timer
var skill_trigger_timer: Timer

# Skills
var skill_executors: Dictionary = {}
var skill_cancelled: bool = false   # <-- Flag para cancelar skill em andamento

# Configurações
@export var horizontal_threshold: float = 160.0
@export var interact_radius: float = 80.0

# Visuais
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: Node2D = $HealthBar
@export var hit_sound: String = "res://assets/sounds/enemies/SlimeDamaged.mp3"

# Controle de down
var downed_66_triggered: bool = false
var downed_33_triggered: bool = false
var downed_1_triggered: bool = false
var current_down_threshold: int = 0
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
	max_health = health
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

# ===== ROTAÇÃO =====
func _update_facing():
	if not isAlive or currentstate != States.IDLE:
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

# ===== SKILLS =====
func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = null

func _on_skill_trigger_timeout():
	if isAlive and currentstate == States.IDLE and skill_cooldown_timer.is_stopped() and not skill_pattern.is_empty():
		_execute_next_skill()

func _execute_next_skill():
	var skill_id = skill_pattern[current_pattern_index]
	current_pattern_index = (current_pattern_index + 1) % skill_pattern.size()
	_execute_skill(skill_id)

func _execute_skill(skill_id: int):
	if target:
		currentstate = States.SKILL_ACTIVE
		velocity = Vector2.ZERO
		skill_cancelled = false

		if skill_executors.has(skill_id):
			await skill_executors[skill_id].call()
		else:
			push_warning("Skill ", skill_id, " não registrada em skill_executors para o boss ", boss_type)
		
		# <-- Verifica se a skill foi cancelada (entrou em DOWNED)
		if skill_cancelled:
			return  # Não finaliza a skill, não inicia cooldown, não muda estado
		
		# Finaliza a skill normalmente
		var cooldown = skills[skill_id].get("cooldown", 3.0)
		skill_cooldown_timer.start(cooldown)
		currentstate = States.IDLE
		_update_facing()

func _on_skill_cooldown_timeout():
	pass

# ===== DANO E LIMIARES =====
func take_damage(damage: int, _attackedpos: Vector2, _kbforce: int) -> void:
	if not isAlive or currentstate == States.DOWNED:
		return

	var old_health = health
	health -= damage
	health = clamp(health, 0, max_health)
	health_bar.updateHealth(health)

	AudioManager.tocar_sfx(position, hit_sound, {Volume = -20.0})
	var tween = create_tween()
	tween.tween_property(animated_sprite, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.1)

	var health_percent = float(health) / max_health * 100.0
	var old_percent = float(old_health) / max_health * 100.0

	# Limiar 66%
	if not downed_66_triggered and old_percent > 66.0 and health_percent <= 66.0:
		health = int(max_health * 0.66)
		health_bar.updateHealth(health)
		enter_down(66)
		return

	# Limiar 33%
	if not downed_33_triggered and old_percent > 33.0 and health_percent <= 33.0:
		health = int(max_health * 0.33)
		health_bar.updateHealth(health)
		enter_down(33)
		return

	# Limiar 1%
	if not downed_1_triggered and downed_33_triggered and old_percent > 1.0 and health_percent <= 1.0:
		health = int(max_health * 0.01)
		health_bar.updateHealth(health)
		enter_down(1)
		return

	# Caso extremo: dano leva a 0 sem acionar 1%
	if health <= 0 and not downed_1_triggered:
		health = int(max_health * 0.01)
		health_bar.updateHealth(health)
		enter_down(1)

func die() -> void:
	isAlive = false
	currentstate = States.SKILL_ACTIVE
	animated_sprite.play("die")
	AudioManager.tocar_sfx(position, hit_sound, {Volume = -10.0, Pitch = 0.7})
	$CollisionShape2D.set_deferred("disabled", true)
	skill_cooldown_timer.stop()
	skill_trigger_timer.stop()
	GameManager.level_completed()

# ===== ESTADO DOWNED =====
func enter_down(threshold: int):
	currentstate = States.DOWNED
	current_down_threshold = threshold
	animated_sprite.play("downed")
	skill_trigger_timer.stop()
	skill_cooldown_timer.stop()   # <-- Para o cooldown
	skill_cancelled = true        # <-- Cancela a skill em execução
	velocity = Vector2.ZERO

	if threshold == 66:
		downed_66_triggered = true
	elif threshold == 33:
		downed_33_triggered = true
	elif threshold == 1:
		downed_1_triggered = true

func exit_down():
	currentstate = States.IDLE
	skill_trigger_timer.start()   # <-- Reinicia o trigger para próxima skill
	_update_facing()

# ===== INTERAÇÃO E QUIZ =====
func _physics_process(_delta):
	if not isAlive:
		return
	match currentstate:
		States.IDLE:
			velocity = Vector2.ZERO
			_update_facing()
		States.SKILL_ACTIVE:
			velocity = Vector2.ZERO
		States.DOWNED:
			velocity = Vector2.ZERO
			if not is_quiz_open and player and Input.is_action_just_pressed("interact"):
				if global_position.distance_to(player.global_position) <= interact_radius:
					_start_quiz()
	move_and_slide()

func _start_quiz():
	is_quiz_open = true
	get_tree().paused = true

	var level = GameManager.currentlevel
	QuizManager.quiz_result.connect(_on_quiz_finished, CONNECT_ONE_SHOT)
	QuizManager.show_quiz("Level" + str(level))

func _on_quiz_finished(correct: bool):
	get_tree().paused = false
	is_quiz_open = false

	if correct:
		if current_down_threshold == 1:
			die()
		else:
			exit_down()
	else:
		if current_down_threshold == 66:
			health = max_health
			health_bar.updateHealth(health)
			downed_66_triggered = false
			downed_33_triggered = false
			downed_1_triggered = false
		elif current_down_threshold == 33:
			health = int(max_health * 0.66)
			health_bar.updateHealth(health)
			downed_33_triggered = false
			downed_1_triggered = false
			if health >= max_health * 0.66:
				downed_66_triggered = true
		elif current_down_threshold == 1:
			health = int(max_health * 0.33)
			health_bar.updateHealth(health)
			downed_1_triggered = false

		exit_down()
