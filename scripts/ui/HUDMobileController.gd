extends CanvasLayer

# ============================================================
# JOYSTICK
# ============================================================
@export_group("Joystick")
@export var deadzone: float = 0.2
@export var knob_max_distance: float = 45.0

@onready var background: Control = $Joystick/Background
@onready var knob: Control = $Joystick/Background/Knob

var touch_index: int = -1
var joystick_pressed: bool = false
var current_vector: Vector2 = Vector2.ZERO

# ============================================================
# BOTÃO DE AÇÃO
# ============================================================
@export_group("Action Button")
@export var action_button_path: NodePath
@export var icon_path: NodePath
@export var attack_icon: Texture2D
@export var interact_icon: Texture2D

@onready var action_button: Button = get_node(action_button_path)
@onready var action_icon: TextureRect = get_node(icon_path)

var is_interact_mode: bool = false

# ============================================================
# READY
# ============================================================
func _ready() -> void:
	if OS.get_name() == "Android" or OS.get_name() == "iOS" or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		_reset_joystick()
		_update_button_icon()

		action_button.button_down.connect(_on_action_button_down)
		action_button.button_up.connect(_on_action_button_up)


# ============================================================
# INPUT (JOYSTICK)
# ============================================================
func _input(event: InputEvent) -> void:
	# --- TOQUE (mobile) ---
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_index == -1 and _is_point_inside(event.position):
				touch_index = event.index
				joystick_pressed = true
				_update_joystick(event.position)
		else:
			if event.index == touch_index:
				touch_index = -1
				joystick_pressed = false
				_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_joystick(event.position)

	# --- MOUSE (PC, para testar) ---
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_point_inside(event.position):
					joystick_pressed = true
					_update_joystick(event.position)
			elif joystick_pressed:
				joystick_pressed = false
				_reset_joystick()

	elif event is InputEventMouseMotion:
		if joystick_pressed:
			_update_joystick(event.position)


func _is_point_inside(point: Vector2) -> bool:
	return background.get_global_rect().has_point(point)


func _get_center() -> Vector2:
	return background.get_global_rect().get_center()


func _update_joystick(point: Vector2) -> void:
	var direction: Vector2 = point - _get_center()
	var distance: float = min(direction.length(), knob_max_distance)
	direction = direction.normalized() * distance if direction.length() > 0 else Vector2.ZERO

	knob.position = background.size / 2 + direction - knob.size / 2
	current_vector = direction / knob_max_distance
	_update_movement_actions()


func _reset_joystick() -> void:
	knob.position = background.size / 2 - knob.size / 2
	current_vector = Vector2.ZERO
	_update_movement_actions()


func _update_movement_actions() -> void:
	if current_vector.x > deadzone:
		Input.action_press("right")
		Input.action_release("left")
	elif current_vector.x < -deadzone:
		Input.action_press("left")
		Input.action_release("right")
	else:
		Input.action_release("left")
		Input.action_release("right")

	if current_vector.y > deadzone:
		Input.action_press("down")
		Input.action_release("up")
	elif current_vector.y < -deadzone:
		Input.action_press("up")
		Input.action_release("down")
	else:
		Input.action_release("up")
		Input.action_release("down")


# ============================================================
# BOTÃO DE AÇÃO (attack / interact)
# ============================================================
func _on_action_button_down() -> void:
	var action_name := "interact" if is_interact_mode else "attack"
	Input.action_press(action_name)


func _on_action_button_up() -> void:
	var action_name := "interact" if is_interact_mode else "attack"
	Input.action_release(action_name)


## Alterna entre modo "attack" e modo "interact" (ícone + ação simulada).
func toggle_action_mode() -> void:
	is_interact_mode = !is_interact_mode
	_update_button_icon()


## Define diretamente o modo. Útil quando o jogo detecta que o player
## está perto de algo interagível, ex: $HUDMobile.set_interact_mode(true)
func set_interact_mode(enabled: bool) -> void:
	is_interact_mode = enabled
	_update_button_icon()


func _update_button_icon() -> void:
	action_icon.texture = interact_icon if is_interact_mode else attack_icon
