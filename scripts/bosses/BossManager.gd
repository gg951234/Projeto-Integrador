class_name BossManager
extends CharacterBody2D

enum States { IDLE, SKILL_ACTIVE, DOWNED }
var currentstate: States = States.IDLE

var boss_type: String = ""
var speed: float
var health: int
var max_health: int
var skill_pattern: Array
var skills: Dictionary
var current_pattern_index: int = 0
var target = null

var isAlive: bool = true
var player: CharacterBody2D = null
var keytarget: CharacterBody2D = null  # Player dentro da keyrange

var skill_cooldown_timer: Timer
var skill_trigger_timer: Timer
var skill_executors: Dictionary = {}
var skill_cancelled: bool = false

@export var horizontal_threshold: float = 160.0
@export var interact_radius: float = 80.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sight: Area2D = $Sight
@onready var keyrange: Area2D = $KeyRange
@onready var health_bar: Node2D = $HealthBar
@export var hit_sound: String = "res://assets/sounds/enemies/SlimeDamaged.mp3"

var outline_shader: Shader = preload("res://shaders/outlineshader.gdshader")
var outline_material: ShaderMaterial = ShaderMaterial.new()
var normal_material: Material
var downedkey_scene: PackedScene = preload("res://scenes/UI/tecla.tscn")
var tecla_instance: AnimatedSprite2D = null

var downed_66_triggered: bool = false
var downed_33_triggered: bool = false
var downed_1_triggered: bool = false
var current_down_threshold: int = 0
var is_quiz_open: bool = false

func _ready():
	add_to_group("boss")
	load_stats()
	setup_timers()
	find_player()
	setup_skill_trigger_timer()
	_update_facing()
	sight.body_entered.connect(_on_sight_body_entered)
	sight.body_exited.connect(_on_sight_body_exited)
	keyrange.body_entered.connect(_on_keyrange_body_entered)
	keyrange.body_exited.connect(_on_keyrange_body_exited)
	normal_material = animated_sprite.material
	outline_material.shader = outline_shader

func load_stats():
	if boss_type.is_empty():
		push_error("BossManager: boss_type não foi definido.")
		return
	var data = BossesData.get_stats(boss_type)
	if data.is_empty():
		push_error("BossManager: dados não encontrados para ", boss_type)
		return
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

func _update_facing():
	if not isAlive or currentstate != States.IDLE:
		return
	if player == null:
		find_player()
	if player == null:
		return
	var delta = player.global_position - global_position
	if abs(delta.x) <= horizontal_threshold:
		if delta.y > 0:
			if animated_sprite.animation != "idle_down":
				animated_sprite.play("idle_down")
		else:
			if animated_sprite.animation != "idle_up":
				animated_sprite.play("idle_up")
	else:
		if delta.x > 0:
			if animated_sprite.animation != "idle_right":
				animated_sprite.play("idle_right")
		else:
			if animated_sprite.animation != "idle_left":
				animated_sprite.play("idle_left")

func _on_sight_body_entered(body: Node2D):
	if body.is_in_group("player"):
		target = body

func _on_sight_body_exited(body: Node2D):
	if body.is_in_group("player"):
		target = null

func _on_keyrange_body_entered(body: Node2D):
	if body.is_in_group("player"):
		keytarget = body
		if currentstate == States.DOWNED and isAlive:
			_add_key_and_outline()

func _on_keyrange_body_exited(body: Node2D):
	if body.is_in_group("player"):
		keytarget = null
		_remove_key_and_outline()

func _add_key_and_outline():
	if tecla_instance == null and isAlive:
		if OS.get_name() == "Android" or OS.get_name() == "iOS":
			tecla_instance = downedkey_scene.instantiate()
			add_child(tecla_instance)
			tecla_instance.position = Vector2(0, -50)
		GameManager._change_mobilebutton("Interact")
		animated_sprite.material = outline_material

func _remove_key_and_outline():
	if tecla_instance != null:
		tecla_instance.queue_free()
		tecla_instance = null
	GameManager._change_mobilebutton("Attack")
	animated_sprite.material = normal_material

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
		if skill_cancelled:
			return
		var cooldown = skills[skill_id].get("cooldown", 3.0)
		skill_cooldown_timer.start(cooldown)
		currentstate = States.IDLE
		_update_facing()

func _on_skill_cooldown_timeout():
	pass

func take_damage(damage: int, _attackedpos: Vector2, _kbforce: int):
	if not isAlive or currentstate == States.DOWNED:
		return
	var old_health = health
	health -= damage
	health = clamp(health, 0, max_health)
	health_bar.updateHealth(health)
	AudioManager.tocar_sfx(position, hit_sound)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "self_modulate", Color.RED, 0.05)
	tween.tween_property(animated_sprite, "self_modulate", Color.WHITE, 0.1)
	var health_percent = float(health) / max_health * 100.0
	var old_percent = float(old_health) / max_health * 100.0
	if not downed_66_triggered and old_percent > 66.0 and health_percent <= 66.0:
		health = int(max_health * 0.66)
		health_bar.updateHealth(health)
		enter_down(66)
		return
	if not downed_33_triggered and old_percent > 33.0 and health_percent <= 33.0:
		health = int(max_health * 0.33)
		health_bar.updateHealth(health)
		enter_down(33)
		return
	if not downed_1_triggered and downed_33_triggered and old_percent > 1.0 and health_percent <= 1.0:
		health = int(max_health * 0.01)
		health_bar.updateHealth(health)
		enter_down(1)
		return
	if health <= 0 and not downed_1_triggered:
		health = int(max_health * 0.01)
		health_bar.updateHealth(health)
		enter_down(1)

func die():
	isAlive = false
	currentstate = States.SKILL_ACTIVE
	animated_sprite.play("die")
	AudioManager.tocar_sfx(position, BossesData.get_stats(boss_type)["diesound"])
	$CollisionShape2D.set_deferred("disabled", true)
	skill_cooldown_timer.stop()
	skill_trigger_timer.stop()
	_remove_key_and_outline()
	keyrange.set_deferred("Monitoring", false)
	GameManager.level_completed()

func enter_down(threshold: int):
	currentstate = States.DOWNED
	current_down_threshold = threshold
	animated_sprite.play("downed")
	skill_trigger_timer.stop()
	skill_cooldown_timer.stop()
	skill_cancelled = true
	velocity = Vector2.ZERO
	keyrange.set_deferred("Monitoring", true)
	# Verifica se o player já está dentro da keyrange
	if keytarget != null and isAlive:
		_add_key_and_outline()
	if threshold == 66:
		downed_66_triggered = true
	elif threshold == 33:
		downed_33_triggered = true
	elif threshold == 1:
		downed_1_triggered = true

func exit_down():
	currentstate = States.IDLE
	skill_trigger_timer.start()
	keyrange.set_deferred("Monitoring", false)
	_remove_key_and_outline()
	_update_facing()

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
				if keytarget:
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
		GameManager.add_score(1000)
		if current_down_threshold == 1:
			die()
		else:
			exit_down()
	else:
		GameManager.add_score(-1000)
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
