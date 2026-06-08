extends BossManager

@export var boss_type_override: String = "Golem"
var levelroot = null

func _ready():
	# Registra as skills dinâmicas antes de inicializar a base
	skill_executors[1] = _skill_rock_fall
	
	boss_type = boss_type_override
	super._ready()
	levelroot = GameManager.currentlevelroot

# Implementação da skill 1 (queda de pedras)
func _skill_rock_fall() -> void:
	if not levelroot:
		return
	
	var params = skills[1]
	var marker_count = params.get("marker_count", 4)
	var marker_radius = params.get("marker_radius", 200)
	var fall_delay = params.get("fall_delay", 1.0)
	var rock_damage = params.get("rock_damage", 20)
	var rock_knockback = params.get("rock_knockback", 300)
	
	var skill_markers: Array[Node2D] = []
	var rock_scene: PackedScene = preload("res://scenes/rock.tscn")
	
	var target_size = 48.0
	var texture = preload("res://assets/images/bosses/Golem/rock_target.png")
	var tex_size = texture.get_size()
	var scale_factor = target_size / max(tex_size.x, tex_size.y)
	
	for i in range(marker_count):
		var marker = Marker2D.new()
		var angle = randf_range(0, TAU)
		var radius = randf_range(100, marker_radius)
		var offset = Vector2(cos(angle), sin(angle)) * radius
		marker.position = position + offset
		
		var sprite = Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2(scale_factor, scale_factor)
		sprite.position = -sprite.texture.get_size() * sprite.scale / 2
		marker.add_child(sprite)
		
		levelroot.add_child(marker)
		skill_markers.append(marker)
	
	await get_tree().create_timer(fall_delay).timeout
	
	for marker in skill_markers:
		if marker and is_instance_valid(marker):
			var rock = rock_scene.instantiate()
			rock.global_position = marker.global_position
			rock.setup(rock_damage, rock_knockback)
			levelroot.add_child(rock)
	
	for m in skill_markers:
		m.queue_free()
	skill_markers.clear()
