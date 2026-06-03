extends CharacterBody2D

signal health_changed(new_health: int)
signal died

var SPEED: float
var health: int
var currentweapon: String
var currentchar: String

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var hitbox_offset: Vector2

var isAlive = true
var knockback_tween: Tween = null   # Referência para o tween ativo

var last_hit_id: int = -1
var hit_sounds: Array[AudioStream] = [
	preload("res://assets/sounds/player/PlayerHit1.mp3"),
	preload("res://assets/sounds/player/PlayerHit2.mp3"),
	preload("res://assets/sounds/player/PlayerHit3.mp3")
]

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
	update_hitbox_offset()

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
# DAR DANO
# --------------

func getHbInfo(dir) -> Dictionary:
	return WeaponsData.get_hitbox(currentweapon).get(dir, { "pos": Vector2(0, 32), "size": Vector2(128, 64) }) # (Direção atual, Default)

func update_hitbox_offset() -> void:
	var direction_key: String = ""
	
	if last_direction.x < 0:
		direction_key = "Left"
	elif last_direction.x > 0:
		direction_key = "Right"
	elif last_direction.y < 0:
		direction_key = "Up"
	elif last_direction.y > 0:
		direction_key = "Down"
		
	var hb_info = getHbInfo(direction_key)
	var shape = sword_collisionbox.shape
	sword_hitbox.position = hb_info["pos"]
	shape.size = hb_info["size"]

func _on_sword_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and (body.is_in_group("enemy") or body.is_in_group("boss")):
		# Busca os dados da arma atual na tabela global
		var dados = WeaponsData.get_stats(currentweapon)
		if dados.is_empty():
			push_error("Tipo de arma desconhecido: ", currentweapon)
			return
		body.take_damage(dados["damage"], position, dados["kb"])

func _on_knockback_finished():
	knockback_tween = null

# --------------
# RECEBER DANO / MORTE
# --------------
func hitSound():
	var new_id = last_hit_id
	while new_id == last_hit_id:
		new_id = randi() % hit_sounds.size()
	
	last_hit_id = new_id
	hit_sound.stream = hit_sounds[new_id]
	hit_sound.play()

func onDied() -> void:
	if not isAlive:
		return  # Evita múltiplas chamadas
	isAlive = false
	animated_sprite_2d.play("die")
	
	hit_sound.pitch_scale = 0.7
	hitSound()
	
	$CollisionShape2D.set_deferred("disabled", true)
	$SwordHitbox/CollisionShape2D.set_deferred("disabled", true)

	await animated_sprite_2d.animation_finished
	var death_screen = load("res://scenes/death_screen.tscn").instantiate()
	get_tree().root.add_child(death_screen)

func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage
	print(health)
	if health <= 0:
		onDied()
		# Emite um sinal
		emit_signal("died")
		return
	
	# Toca som
	hitSound()
	
	# Emite um sinal
	emit_signal("health_changed", health)
	
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
