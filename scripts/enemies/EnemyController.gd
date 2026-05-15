extends CharacterBody2D

var velocidade: float = 50.0
var direcao: Vector2 = Vector2.RIGHT

func _physics_process(_delta: float) -> void:
	velocity = direcao * velocidade
	move_and_slide()
	if is_on_wall():
		direcao = -direcao
