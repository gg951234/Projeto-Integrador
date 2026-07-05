extends CharacterBody2D

signal health_changed(new_health: int)
signal died

# --- SKIN SYSTEM ---
# Mapeia o nome do personagem (currentchar) para o caminho do arquivo .tres
const SKIN_PATHS := {
	"Default": "res://scenes/player/defaultskin.tres",
	"Gold": "res://scenes/player/goldskin.tres",
	"Frost": "res://scenes/player/frostskin.tres",
	"Shadow": "res://scenes/player/shadowskin.tres",
}
# ------------------

var SPEED: float
var health: int
var currentchar: String

var last_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var hitbox_offset: Vector2

var isAlive = true
var knockback_tween: Tween = null

var last_hit_id: int = -1
var hit_sounds: Array[String] = [
	"res://assets/sounds/player/PlayerHit1.mp3",
	"res://assets/sounds/player/PlayerHit2.mp3",
	"res://assets/sounds/player/PlayerHit3.mp3"
]
@onready var swing_sword: String = "res://assets/sounds/player/Slash1.mp3"

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: Area2D = $SwordHitbox
@onready var sword_collisionbox: CollisionShape2D = $SwordHitbox/CollisionShape2D

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready() -> void:
	add_to_group("player")
	hitbox_offset = sword_hitbox.position

	currentchar = PlayerData.obter_skin_equipada() # Skin comprada/equipada na Loja

	# Aplica a skin baseada no currentchar ANTES de carregar as stats (opcional, mas visual)
	apply_skin(currentchar)

	var dados = CharactersData.get_stats(currentchar)
	if dados.is_empty():
		push_error("Tipo de personagem desconhecido: ", currentchar, ". Usando stats de Default.")
		currentchar = "Default"
		dados = CharactersData.get_stats(currentchar)
		
	SPEED = dados["speed"]
	health = dados["health"]

func _physics_process(_delta: float) -> void:
	sword_hitbox.monitoring = false

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
# SISTEMA DE SKIN
# --------------
func apply_skin(skin_name: String) -> void:
	# Converte para minúsculo para evitar erros de digitação
	var key = skin_name
	var path = SKIN_PATHS.get(key)
	
	# Se não encontrar, usa a skin "Default" como fallback
	if path == null:
		push_warning("Skin não encontrada: ", skin_name, ". Usando Default.")
		path = SKIN_PATHS["Default"]
	
	var new_frames: SpriteFrames = load(path)
	if new_frames:
		animated_sprite_2d.sprite_frames = new_frames
		# Tenta manter a mesma animação que estava rodando (ex: "idle_side")
		var current_anim = animated_sprite_2d.animation
		if current_anim and animated_sprite_2d.sprite_frames.has_animation(current_anim):
			animated_sprite_2d.play(current_anim)
		else:
			# Fallback: toca a animação "idle_down" se existir
			if animated_sprite_2d.sprite_frames.has_animation("idle_down"):
				animated_sprite_2d.play("idle_down")
			else:
				animated_sprite_2d.play()  # toca a primeira animação disponível
	else:
		push_error("Falha ao carregar SpriteFrames: ", path)

# --------------
# MOVIMENTAÇÃO
# --------------
func process_movement() -> void:
	var direction := Input.get_vector("left", "right", "up", "down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
	else:
		velocity = Vector2.ZERO

func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_anims("run", last_direction)
	else:
		play_anims("idle", last_direction)

func play_anims(prefix: String, dir: Vector2) -> void:
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
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
	AudioManager.tocar_sfx(position, swing_sword)
	play_anims("attack", last_direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

# --------------
# DAR DANO
# --------------
func getHbInfo(dir) -> Dictionary:
	return CharactersData.get_hitbox(currentchar).get(dir, { "pos": Vector2(0, 32), "size": Vector2(128, 64) })

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
		var dados = CharactersData.get_stats(currentchar)
		if dados.is_empty():
			push_error("Tipo de personagem desconhecido: ", currentchar)
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
	AudioManager.tocar_sfx(position, hit_sounds[new_id])

func onDied() -> void:
	if not isAlive:
		return
	isAlive = false
	animated_sprite_2d.play("die")
	AudioManager.tocar_sfx(position, hit_sounds[1], {Pitch = 0.7})
	$CollisionShape2D.set_deferred("disabled", true)
	$SwordHitbox/CollisionShape2D.set_deferred("disabled", true)
	await animated_sprite_2d.animation_finished
	var death_screen = load("res://scenes/UI/death_screen.tscn").instantiate()
	get_tree().root.add_child(death_screen)

func take_damage(damage: int, attackedpos: Vector2, kbforce: int) -> void:
	health -= damage

	if health <= 0:
		onDied()
		emit_signal("died")
		return

	hitSound()
	emit_signal("health_changed", health)

	var tween = create_tween()
	tween.tween_property(animated_sprite_2d, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite_2d, "self_modulate", Color.WHITE, 0.1)

	if knockback_tween and knockback_tween.is_valid():
		knockback_tween.kill()

	var kbdirection = (position - attackedpos).normalized()
	velocity = kbdirection * (kbforce * 6)
	knockback_tween = create_tween()
	knockback_tween.tween_property(self, "velocity", Vector2.ZERO, 0.3).set_ease(Tween.EASE_OUT)
	knockback_tween.finished.connect(_on_knockback_finished)
