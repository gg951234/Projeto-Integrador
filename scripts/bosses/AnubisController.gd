extends BossManager

@export var boss_type_override: String = "Anubis"
@onready var skill1sound: String = "res://assets/sounds/bosses/ByBy/TrainSteam.mp3"
@onready var rocksmashsound: String = "res://assets/sounds/bosses/Golem/RockSmash.mp3"
@onready var rock_texture = preload("res://assets/images/bosses/Golem/rock.png")
@onready var circlepreview_texture = preload("res://assets/images/bosses/circletarget.png")
@onready var rock_particles_scene = preload("res://scenes/bosses/Golem/rock_particle.tscn")
@onready var spinline_texture = preload("res://assets/images/bosses/Anubis/SpinLineTexture.png")

var levelroot = null

func _ready():
	skill_executors[1] = _skill_1
	skill_executors[2] = _skill_2
	boss_type = boss_type_override
	super._ready()
	await get_tree().process_frame
	
	if str(get_tree().root) == "LevelRoot":
		levelroot = get_tree().root
	else:
		levelroot = GameManager.currentlevelroot

func _on_damage_area_body_entered(body: Node, damage: int, kb: int, area: Area2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, area.global_position, kb)

func _skill_1() -> void:
	if not levelroot:
		print("No Levelroot")
		return
	
	var params = skills[1]
	var anim_name = "skill_1"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
		var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		var anim_length = frame_count / fps if fps > 0 else 1.0
		
		await get_tree().create_timer(anim_length).timeout
		
		if currentstate == States.SKILL_ACTIVE:
			AudioManager.tocar_sfx(position, skill1sound, {Pitch = 0.5})
			animated_sprite.play("idle_down")
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
	
	if currentstate == States.SKILL_ACTIVE:
		spin_line_attack(params)

func spin_line_attack(params) -> void:
	var length = params.get("length", 300.0)       # tamanho ajustável da linha
	var thickness = params.get("thickness", 20.0)   # espessura da linha
	var damage = params.get("damage", 20)
	var knockback = params.get("knockback", 300)
	var spin_speed = params.get("spin_speed", 180.0) # graus por segundo
	var duration = params.get("duration", 4.0)       # tempo total girando

	# Visual da linha
	var sprite = Sprite2D.new()
	sprite.texture = spinline_texture
	sprite.rotation = PI / 2  # começa na horizontal
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect.size = Vector2(32, length/2)
	sprite.scale.y = 2
	sprite.global_position = position
	levelroot.add_child(sprite)

	# Área de dano acompanhando a linha
	var damage_area = Area2D.new()
	damage_area.collision_layer = 2
	damage_area.collision_mask = 2

	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(length, thickness)
	collision_shape.shape = shape
	collision_shape.rotation = 0.0
	damage_area.add_child(collision_shape)
	damage_area.global_position = position
	levelroot.add_child(damage_area)
	
	AudioManager.tocar_sfx(position, skill1sound, {Pitch = 1.2})
	
	damage_area.body_entered.connect(_on_damage_area_body_entered.bind(
		damage,
		knockback,
		damage_area
	))
	
	var elapsed = 0.0
	while elapsed < duration:
		var dt = get_process_delta_time()
		sprite.rotation += deg_to_rad(spin_speed) * dt
		damage_area.rotation += deg_to_rad(spin_speed) * dt
		
		elapsed += dt
		await get_tree().process_frame
	
	sprite.queue_free()
	damage_area.queue_free()

func _skill_2() -> void:
	if not levelroot:
		print("No Levelroot")
		return
	
	var params = skills[2]
	var count = params.get("count", 4)

	# Toca animação correspondente (skill_<id>)
	var anim_name = "skill_1"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		var frame_count = animated_sprite.sprite_frames.get_frame_count(anim_name)
		var fps = animated_sprite.sprite_frames.get_animation_speed(anim_name)
		var anim_length = frame_count / fps if fps > 0 else 1.0
		
		# Aguarda o tempo exato da animação com Timer
		await get_tree().create_timer(anim_length).timeout
		
		if currentstate == States.SKILL_ACTIVE:
			AudioManager.tocar_sfx(position, skill1sound, {Pitch = 0.5})
			animated_sprite.play("idle_down")
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
		
	if currentstate == States.SKILL_ACTIVE:
		# 1. Criar previews das áreas de impacto
		for i in range(count):
			permarocks_spawn(params)
			
		await get_tree().create_timer(params.get("delay", 1.0)+0.4).timeout
		AudioManager.tocar_sfx(position, rocksmashsound)

func permarocks_spawn(params) -> void:
	var delay = params.get("delay", 1.0)
	var damage = params.get("damage", 20)
	var knockback = params.get("knockback", 300)
	var impact_scale = params.get("impact_scale", 32.0)
	var skill_duration = params.get("skill_duration", 32.0)
	
	var square_size = params.get("square_size", 1408.0)
	var half = square_size / 2.0
	var offset_x = randf_range(-half, half)
	var offset_y = randf_range(-half, half)
	var target_pos = position + Vector2(offset_x, offset_y)
	
	# Preview
	var preview = Sprite2D.new()
	preview.texture = circlepreview_texture
	preview.scale = Vector2(impact_scale, impact_scale)
	preview.global_position = target_pos
	preview.modulate = Color(1, 1, 1, 0.7)
	levelroot.add_child(preview)
	
	await get_tree().create_timer(delay).timeout
	await get_tree().create_timer(0.4).timeout

	preview.queue_free()
	
	# Partículas e área de dano
	var rock = Sprite2D.new()
	rock.texture = rock_texture
	rock.scale = Vector2(impact_scale, impact_scale)
	rock.global_position = target_pos
	rock.z_index = 1
	levelroot.add_child(rock)
	
	var particles = rock_particles_scene.instantiate()
	particles.global_position = target_pos
	levelroot.add_child(particles)
	particles.z_index = 2
	particles.emitting = true
	
	for subparticles in particles.get_children():
		particles.z_index = 2
		subparticles.emitting = true
	
	var damage_area = Area2D.new()
	damage_area.collision_layer = 2
	damage_area.collision_mask = 2
	damage_area.scale = Vector2(impact_scale*impact_scale, impact_scale*impact_scale)
	
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 11.0
	collision_shape.shape = shape
	damage_area.add_child(collision_shape)
	damage_area.global_position = target_pos
	
	damage_area.body_entered.connect(_on_damage_area_body_entered.bind(
		damage,
		knockback,
		damage_area
	))
	
	levelroot.add_child(damage_area)
	await get_tree().create_timer(skill_duration).timeout
	rock.queue_free()
	damage_area.queue_free()
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()
