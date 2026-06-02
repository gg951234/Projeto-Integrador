extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		audio_stream_player_2d.play()
		collision_shape_2d.set_deferred("disabled", true)
		animated_sprite_2d.visible = false
		GameManager.add_coins(1)
		await audio_stream_player_2d.finished  # Espera o som acabar
		queue_free()
