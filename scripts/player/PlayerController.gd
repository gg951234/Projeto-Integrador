extends CharacterBody2D

const VELOCIDADE := 100.0

func _physics_process(_delta: float) -> void:
	var direcao := Vector2(
		Input.get_axis("mover_esquerda", "mover_direita"),
		Input.get_axis("mover_cima", "mover_baixo")
	)
	if direcao != Vector2.ZERO:
		direcao = direcao.normalized()
	velocity = direcao * VELOCIDADE
	move_and_slide()
