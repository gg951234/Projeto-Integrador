extends Area2D

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var coin_sound: String = "res://assets/sounds/collectables/Coin.mp3"

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collision_shape_2d.set_deferred("disabled", true)
		animated_sprite_2d.visible = false
		GameManager.add_coins()
		GameManager.add_score(1000)
		AudioManager.tocar_sfxglobal(coin_sound)
		queue_free()
