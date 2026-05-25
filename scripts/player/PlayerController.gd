extends CharacterBody2D

var SPEED: float
var health: int
var currentweapon: String
var currentchar: String

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var hitbox_offset: Vector2

var isAlive = true
var knockback_tween: Tween = null   # Referência para o tween ativo

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swing_sword: AudioStreamPlayer2D = $SwingSword
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_collisionbox: CollisionShape2D = $SwordHitbox/CollisionShape2D
@onready var hit_sound: AudioStreamPlayer2D = $HitSound

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready() -> void: # Executa quando o nó é criado
	add_to_group("player")
	hitbox_offset = sword_hitbox.position

	currentweapon = "Sword" # IMPLEMENTAR PARA PUXAR DO BANCO DE DADOS
	currentchar = "Default" # IMPLEMENTAR PARA PUXAR DO BANCO DE DADOS
	
	var dados = CharactersData.get_stats(currentchar)
	if dados.is_empty():
		push_error("Tipo de personagem desconhecido: ", currentchar)
		return
	SPEED = dados["speed"]
	health = dados["health"]

func _physics_process(_delta: float) -> void: # Executa a cada frame
	sword_hitbox.monitoring = false # Desativa a hitbox a todo momento
	
	if Input.is_action_just_pressed("attack") and isAlive and not is_attacking:
		attack()

	if is_attacking:
		velocity = Vector2.ZERO
		return

	if isAlive and knockback_tween == null:
			process_movement()
			process_animation()

	if isAlive:
		move_and_slide()

# --------------
# MOVIMENTAÇÃO
# --------------
func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down") # Inputs em Projeto>Configurações>Mapa de Entrada
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED # Mover para direção * velocidade
		last_direction = direction
		update_hitbox_offset()
	else:
		velocity = Vector2.ZERO

func process_animation() -> void: # Processar se está parado ou andando
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_anims("run", last_direction)
	else:
		play_anims("idle", last_direction)

func play_anims(prefix: String, dir: Vector2) -> void: # Tocar animações
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0 # Virar o sprite pra esquerda/direita
		animated_sprite_2d.play(prefix + "_side")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	elif dir.y > 0:
		animated_sprite_2d.play(prefix + "_down")

# --------------
# ATACAR/INTERAGIR
# --------------
func attack() -> void:
	is_attacking = true
	sword_hitbox.monitoring = true
	swing_sword.play()
	play_anims("attack", last_direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

# --------------
# HITBOX
# --------------
func update_hitbox_offset() -> void:
	var defaulthb = {
		Vector2.DOWN:  { "pos": Vector2(0,  32), "size": Vector2(128, 64) },
		Vector2.UP:    { "pos": Vector2(0, -12), "size": Vector2(128, 64) },
		Vector2.RIGHT: { "pos": Vector2(4, 20), "size": Vector2(120, 72) },
		Vector2.LEFT:  { "pos": Vector2(-4, 20), "size": Vector2(120, 72) },
	}
	
	var info = defaulthb.get(last_direction, { "pos": Vector2(0, 32), "size": Vector2(128, 64) }) # (Direção atual, Default)
	sword_hitbox.position = info["pos"]
	
	var shape = sword_collisionbox.shape
	if shape is RectangleShape2D:
		shape.size = info["size"]
	else:
		# Caso a shape não seja retangular, logar um erro
		print("Aviso: sword_collisionbox.shape não é um RectangleShape2D")


func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and (body.is_in_group("enemy") or body.is_in_group("boss")): # Seção somente para Slimes
		# print("Hit: " + body.name)
		# Busca os dados da arma atual na tabela global
		var dados = WeaponsData.get_stats(currentweapon)
		if dados.is_empty():
			push_error("Tipo de arma desconhecido: ", currentweapon)
			return
		body.take_damage(dados["damage"], position, dados["kb"])

func _on_knockback_finished():
	knockback_tween = null

func onDied() -> void:
	isAlive = false
	animated_sprite_2d.play("die")
	hit_sound.pitch_scale = 0.7
	hit_sound.play()
	$CollisionShape2D.set_deferred("disabled", true)
	$SwordHitbox/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(2.0).timeout
	print("Resetou Level")
	isAlive = true
	GameManager.load_level() # Pega o número da fase e tenta carregar

func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage
	print(health)
	if health <= 0:
		onDied()
		return
	
	hit_sound.play()
	
	# Pisca em vermelho
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
