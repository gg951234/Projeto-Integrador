extends Area2D

var damage: int = 20
var knockback_force: int = 300
var fall_speed: float = 400.0
var target_y: float   # posição Y do chão

func setup(dmg: int, kb: int) -> void:
	damage = dmg
	knockback_force = kb

func _ready():
	# Começa 200 pixels acima da posição final
	target_y = global_position.y
	global_position.y -= 200
	# Anima a queda
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", target_y, 0.3).set_ease(Tween.EASE_IN)
	await tween.finished
	_explode()

func _explode() -> void:
	# Aplica dano e knockback em quem estiver dentro da área
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			# Direção do knockback: do centro da pedra para o corpo
			var dir = (body.global_position - global_position).normalized()
			body.take_damage(damage, global_position, knockback_force, dir)
	# Opcional: efeito visual de impacto
	var particles = $GPUParticles2D
	particles.one_shot = true
	particles.emitting = true
	await get_tree().create_timer(0.2).timeout
	queue_free()
