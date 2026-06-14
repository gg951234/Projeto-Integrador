extends BossManager

@export var boss_type_override: String = "Golem"
var levelroot = null

func _ready():
	skill_executors[1] = _skill_1
	boss_type = boss_type_override
	super._ready()
	await get_tree().process_frame
	
	if str(get_tree().root) == "LevelRoot":
		levelroot = get_tree().root
	else:
		levelroot = GameManager.currentlevelroot

func _skill_1() -> void:
	if not levelroot:
		print("No Levelroot")
		return
	
	var params = skills[1]
	var rock_count = params.get("rock_count", 4)
	
	# Toca animação correspondente (skill_<id>)
	var anim_name = "skill_1"
	if animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
		await animated_sprite.animation_finished
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
	
	# 1. Criar previews das áreas de impacto
	for i in range(rock_count):
		rock_spawn(params)

func _on_damage_area_body_entered(body: Node, damage: int, kb: int, area: Area2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, area.position, kb)

func rock_spawn(params) -> void:
	var spawn_range = params.get("spawn_range", 200)
	var fall_delay = params.get("fall_delay", 1.0)
	var rock_damage = params.get("rock_damage", 20)
	var rock_knockback = params.get("rock_knockback", 300)
	var impact_scale = params.get("impact_scale", 32.0)
	
	var preview_texture = preload("res://assets/images/bosses/Golem/rock_target.png")
	var rock_texture = preload("res://assets/images/bosses/Golem/rock.png")
	var impact_particles_scene = preload("res://scenes/bosses/Golem/rock_particle.tscn")
	
	var angle = randf_range(0, TAU)
	var radius = randf_range(100, spawn_range)
	var offset = Vector2(cos(angle), sin(angle)) * radius
	var target_pos = position + offset
	
	var preview = Sprite2D.new()
	preview.texture = preview_texture
	preview.scale = Vector2(impact_scale, impact_scale)
	preview.global_position = target_pos
	preview.modulate = Color(1, 1, 1, 0.7)
	levelroot.add_child(preview)
	
	await get_tree().create_timer(fall_delay).timeout
	
	# 2. Queda simultânea das pedras
	var rock = Sprite2D.new()
	rock.texture = rock_texture
	rock.scale = Vector2(impact_scale, impact_scale)
	rock.global_position = target_pos + Vector2(0, -150)
	rock.z_index = 1
	levelroot.add_child(rock)
	
	var tween = create_tween()
	tween.tween_property(rock, "global_position:y", target_pos.y, 0.4).set_ease(Tween.EASE_IN)
	
	# Aguarda todas as quedas terminarem
	await get_tree().create_timer(0.4).timeout
	
	rock.queue_free()
	preview.queue_free()
	
	# 3. Criar áreas de dano (layer/mask = 2) e partículas
	var particles = impact_particles_scene.instantiate()
	particles.global_position = target_pos
	levelroot.add_child(particles)
	particles.emitting = true
	particles.z_index = 2
	
	# Área de dano com collision_layer e mask configurados para 2
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
	
	# Aplica dano a todos os jogadores sobrepostos
	damage_area.body_entered.connect(_on_damage_area_body_entered.bind(
	rock_damage,
	rock_knockback,
	damage_area
	))
	
	levelroot.add_child(damage_area)
	
	# Aguarda um tempo para que as áreas sejam processadas
	await get_tree().create_timer(0.2).timeout
	
	# Limpeza das hitboxes
	damage_area.queue_free()
	
	# Limpeza com delay da duração das partículas
	await get_tree().create_timer(particles.lifetime).timeout
	
	particles.queue_free()
