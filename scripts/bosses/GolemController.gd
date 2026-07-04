extends BossManager

@export var boss_type_override: String = "Golem"
@onready var rocksmashsound: String = "res://assets/sounds/bosses/Golem/RockSmash.mp3"

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
		AudioManager.tocar_sfx(position, rocksmashsound, {Pitch = 0.5})
		animated_sprite.play("idle_down")
	else:
		push_warning("Animação ", anim_name, " não encontrada para o boss ", boss_type)
		
	if currentstate == States.SKILL_ACTIVE:
		# 1. Criar previews das áreas de impacto
		for i in range(count):
			rock_spawn(params)
		
		await get_tree().create_timer(params.get("delay", 1.0)+0.4).timeout
		AudioManager.tocar_sfx(position, rocksmashsound)

func _on_damage_area_body_entered(body: Node, damage: int, kb: int, area: Area2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage, area.position, kb)

func rock_spawn(params) -> void:
	var delay = params.get("delay", 1.0)
	var damage = params.get("damage", 20)
	var knockback = params.get("knockback", 300)
	var impact_scale = params.get("impact_scale", 32.0)
	
	var preview_texture = preload("res://assets/images/bosses/circletarget.png")
	var rock_texture = preload("res://assets/images/bosses/Golem/rock.png")
	var impact_particles_scene = preload("res://scenes/bosses/Golem/rock_particle.tscn")
	
	var square_size = params.get("square_size", 1408.0)
	var half = square_size / 2.0
	var offset_x = randf_range(-half, half)
	var offset_y = randf_range(-half, half)
	var target_pos = position + Vector2(offset_x, offset_y)
	
	# Preview
	var preview = Sprite2D.new()
	preview.texture = preview_texture
	preview.scale = Vector2(impact_scale, impact_scale)
	preview.global_position = target_pos
	preview.modulate = Color(1, 1, 1, 0.7)
	levelroot.add_child(preview)
	
	await get_tree().create_timer(delay).timeout
	
	# Queda da pedra
	var rock = Sprite2D.new()
	rock.texture = rock_texture
	rock.scale = Vector2(impact_scale, impact_scale)
	rock.global_position = target_pos + Vector2(0, -150)
	rock.z_index = 1
	levelroot.add_child(rock)

	var tween = create_tween()
	var rotacao = 3
	tween.tween_property(rock, "global_position:y", target_pos.y, 0.4).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(rock, "rotation", rotacao, 0.4).set_ease(Tween.EASE_IN)
	
	await get_tree().create_timer(0.4).timeout
	
	rock.queue_free()
	preview.queue_free()
	
	# Partículas e área de dano
	var particles = impact_particles_scene.instantiate()
	particles.global_position = target_pos
	levelroot.add_child(particles)
	particles.emitting = true
	particles.z_index = 2
	
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
	await get_tree().create_timer(0.2).timeout
	damage_area.queue_free()
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()
