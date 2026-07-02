extends Node2D

@onready var voltar: Button = $CanvasLayer/Voltar

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var original_scale: Vector2 = Vector2(1, 1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

func _ready() -> void:
	voltar.pivot_offset = voltar.size / 2

	voltar.mouse_entered.connect(_on_button_mouse_entered.bind(voltar))
	voltar.mouse_exited.connect(_on_button_mouse_exited.bind(voltar))


func _process(delta: float) -> void:
	pass

func _on_button_mouse_entered(button: Button) -> void:
	animate_scale(button, hover_scale)

func _on_button_mouse_exited(button: Button) -> void:
	animate_scale(button, original_scale)

func animate_scale(button: Button, target_scale: Vector2) -> void:
	var buttontween = create_tween()
	buttontween.set_ease(tween_type)
	buttontween.set_trans(tween_trans)
	buttontween.tween_property(button, "scale", target_scale, animation_duration)

func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
