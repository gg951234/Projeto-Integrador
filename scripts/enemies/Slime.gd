extends CharacterBody2D
@export var enemy_type: String = "Slime"

var SPEED: float
var health: int
var target = null
var isAlive = true

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound
@onready var health_bar: Node2D = $HealthBar

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready(): # Executa quando o nó é criado
	# Busca os dados do inimigo na tabela global
	var dados = EnemiesData.get_stats(enemy_type)
	if dados.is_empty():
		push_error("Tipo de inimigo desconhecido: ", enemy_type)
		return
	
	SPEED = dados["speed"]
	health = dados["health"]

func _physics_process(delta: float) -> void: # Executa a cada frame
	if isAlive and target:
		_moveToTarget(delta)
	move_and_slide()
	
# --------------
# MOVIMENTAÇÃO
# --------------
func _moveToTarget(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	animated_sprite_2d.play("attack")

# --------------
# DANO
# --------------
func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage
	health_bar.updateHealth(health)
	
	if health <= 0: # Se a vida for menor que 0 chama a função de morte
		onDied()
	
	hit_sound.play()
	# Knockback
	var kbdirection = (position - attackedpos).normalized()
	var kbpos = position + kbdirection * kbforce
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position", kbpos, 0.3)

func onDied() -> void:
	isAlive = false
	animated_sprite_2d.play("die")
	hit_sound.pitch_scale = 0.7
	hit_sound.play()
	
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)

# --------------
# DETECÇÃO
# --------------
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and isAlive:
		target = null
		animated_sprite_2d.play("idle")
