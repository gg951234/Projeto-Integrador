class_name BossManager
extends CharacterBody2D

# Estados
enum State { IDLE, SKILL_ACTIVE }
var state: State = State.IDLE

# Estatísticas comuns (carregadas do BossesData)
var boss_type: String = ""
var speed: float          # reservado para skills que exigem movimento
var health: int
var skill_pattern: Array  # ex: [1, 2, 1, 3]
var skills: Dictionary     # { id: { cooldown, outros parâmetros } }
var current_pattern_index: int = 0

# Combate e sobrevivência
var isAlive: bool = true
var player: CharacterBody2D = null

# Timers
var skill_cooldown_timer: Timer     # cooldown individual da última skill
var skill_trigger_timer: Timer      # periodicamente tenta executar próxima skill

# Sistema de skills dinâmicas
var skill_executors: Dictionary = {}   # { skill_id: Callable }

# Ajuste visual
@export var horizontal_threshold: float = 160.0

# Referências visuais
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var health_bar: Node2D = $HealthBar

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
	
	# Se a diferença horizontal for pequena → jogador está acima ou abaixo
	if abs(delta.x) <= horizontal_threshold:
		# Vira para cima ou para baixo (resetando flip_h)
		animated_sprite.flip_h = false
		if delta.y > 0:
			if animated_sprite.animation != "idle_down":
				animated_sprite.play("idle_down")
		else:
			if animated_sprite.animation != "idle_up":
				animated_sprite.play("idle_up")
	else:
		# Jogador está à esquerda ou direita → vira para o lado com flip
		animated_sprite.flip_h = (delta.x < 0)
		if animated_sprite.animation != "idle_side":
			animated_sprite.play("idle_side")

# ===== SISTEMA DE SKILLS DINÂMICO =====
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
	
	# Toca animação correspondente (skill_<id>)
	var anim_name = "skill_" + str(skill_id)
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		await animated_sprite.animation_finished
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
	
	# Executa o callable registrado para esta skill, se existir
	if skill_executors.has(skill_id):
		await skill_executors[skill_id].call()
	else:
		push_warning("Skill ", skill_id, " não registrada em skill_executors para o boss ", boss_type)
	
	# Cooldown e retorno ao idle
	var cooldown = skills[skill_id].get("cooldown", 3.0)
	skill_cooldown_timer.start(cooldown)
	state = State.IDLE
	_update_facing()

func _on_skill_cooldown_timeout():
	# Opcional: usado para indicar que skill pode ser usada novamente
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
	skill_trigger_timer.stop()

func _physics_process(_delta: float):
	if not isAlive:
		return
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_update_facing()
		State.SKILL_ACTIVE:
			velocity = Vector2.ZERO
	move_and_slide()
