extends CharacterBody2D

signal died   # <--- NOVO SINAL

@export var enemy_type: String = name

var SPEED: float
var health: int

var target = null
var target_in_range: bool = false
var isAlive: bool = true
var knockback_tween: Tween = null   # Referência para o tween ativo

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: String = "res://assets/sounds/enemies/SlimeDamaged.mp3"
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer

func _ready():
	add_to_group("enemy")
	var dados = EnemiesData.get_stats(enemy_type)
	if dados.is_empty():
		push_error("Tipo de inimigo desconhecido: ", enemy_type)
		return
	SPEED = dados["speed"]
	health = dados["health"]
	attack_timer.wait_time = dados["attackcd"]

func _physics_process(_delta: float) -> void:
	if isAlive and knockback_tween == null:
		# Só segue o player se NÃO estiver em knockback
		if target != null:
			_moveToTarget()
		elif target == null:
			velocity = Vector2.ZERO
	if isAlive:
		move_and_slide()

func _moveToTarget() -> void:
	var distance = position.distance_to(target.position)
	if distance < 1: # Se estiver muito perto, não se move
		velocity = Vector2.ZERO
		return
	var direction = (target.position - position).normalized()
	velocity = direction * SPEED

func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage
	health_bar.updateHealth(health)
	if health <= 0:
		onDied()
		return
	
	AudioManager.tocar_sfx(position, hit_sound)
	
	# Pisca em branco
	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite_2d, "self_modulate", Color.WHITE, 0.1)
	
	# Cancela qualquer tween anterior
	if knockback_tween and knockback_tween.is_valid():
		knockback_tween.kill()
	
	# Define a direção do knockback
	var kbdirection = (position - attackedpos).normalized()
	velocity = kbdirection * (kbforce * 6)   # Força inicial * 6 para ajustar a potência
	
	# Cria um tween para reduzir a velocidade gradualmente até zero
	knockback_tween = create_tween()
	knockback_tween.tween_property(self, "velocity", Vector2.ZERO, 0.3).set_ease(Tween.EASE_OUT)
	# Quando o tween terminar, libera a referência
	knockback_tween.finished.connect(_on_knockback_finished)

func _on_knockback_finished():
	knockback_tween = null

func onDied() -> void:
	isAlive = false
	animated_sprite_2d.play("die")
	
	AudioManager.tocar_sfx(position, hit_sound, {Pitch = 0.7})
	GameManager.add_score(10)
	
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	died.emit()   # Emite sinal para o GameManager

func _on_sight_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") and isAlive:
		target = null
		animated_sprite_2d.play("idle")

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and attack_timer.time_left <= 0:
		target_in_range = true
		attack_timer.start()
		
		# Busca os dados do inimigo atual na tabela global
		var dados = EnemiesData.get_stats(enemy_type)
		if dados.is_empty():
			push_error("Dano não registrado: ", enemy_type)
			return
		body.take_damage(dados["damage"], position, dados["kb"])

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		target_in_range = false

func _on_attack_timer_timeout() -> void:
	attack_timer.stop()
	if target and target_in_range:
		# Busca os dados do inimigo atual na tabela global
		var dados = EnemiesData.get_stats(enemy_type)
		if dados.is_empty():
			push_error("Dano não registrado: ", enemy_type)
			return
		target.take_damage(dados["damage"], position, dados["kb"])
