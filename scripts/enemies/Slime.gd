extends CharacterBody2D

@export var enemy_type: String = "Slime"

var SPEED: float
var health: int
var target = null
var isAlive = true
var knockback_tween: Tween = null   # Referência para o tween ativo

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var health_bar: Node2D = $HealthBar

func _ready():
	add_to_group("enemy")
	var dados = EnemiesData.get_stats(enemy_type)
	if dados.is_empty():
		push_error("Tipo de inimigo desconhecido: ", enemy_type)
		return
	SPEED = dados["speed"]
	health = dados["health"]

func _physics_process(_delta: float) -> void:
	if isAlive and target and knockback_tween == null:
		# Só segue o player se NÃO estiver em knockback
		_moveToTarget()
	elif knockback_tween == null:
		# Sem knockback e sem alvo → para
		velocity = Vector2.ZERO
	# Se knockback_tween não for nulo, não alteramos a velocity (ela está sendo controlada pelo tween)
	
	move_and_slide()

func _moveToTarget() -> void:
	var direction = (target.position - position).normalized()
	velocity = direction * SPEED
	animated_sprite_2d.play("attack")

func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage
	health_bar.updateHealth(health)
	if health <= 0:
		onDied()
		return
	
	hit_sound.play()
	
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
	hit_sound.pitch_scale = 0.7
	hit_sound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)

func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and isAlive:
		target = null
		animated_sprite_2d.play("idle")
