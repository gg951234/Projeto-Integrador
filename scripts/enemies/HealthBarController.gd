extends Node2D

@onready var health_bar: Sprite2D = $Health
@onready var defaultWidth = health_bar.region_rect.size.x
@onready var defaultHeight = health_bar.region_rect.size.y

func updateHealth(newHealth: int) -> void:
	# Resize health bar
	var newWidth = (newHealth / 100.0) * defaultWidth
	health_bar.region_rect = Rect2(0, 0, newWidth, defaultHeight)
