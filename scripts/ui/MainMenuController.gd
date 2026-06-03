extends Control

@onready var hud: CanvasLayer = $HUD
@onready var health_bar: TextureProgressBar = $HUD/HealthBar

@onready var start: Button = $MainMenuCanvas/Buttons/Start
@onready var options: Button = $MainMenuCanvas/Buttons/Options
@onready var quit: Button = $MainMenuCanvas/Buttons/Quit
@onready var main_menu_canvas: CanvasLayer = $MainMenuCanvas
@onready var level_selection_canvas: CanvasLayer = $LevelSelectionCanvas
@onready var level_selection_buttons: VBoxContainer = $LevelSelectionCanvas/Buttons

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

var original_scale: Vector2 = Vector2(1, 1)
var buttontween: Tween

var levels_setup_done: bool = false

var player
var max_health

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready() -> void:  # Executa quando o nó é criado
	# Aguarda um frame para o VBoxContainer ajustar os tamanhos
	await get_tree().process_frame
	setup_main_buttons()

# --------------
# SETAR PLAYER
# --------------
func set_player(p) -> void:
	player = p
	if player:
		hud.visible = true
		max_health = player.health
		player.health_changed.connect(_update_health)
		player.died.connect(_hide_HUD)
		_update_health(player.health)

func _hide_HUD() -> void:
	hud.visible = false

func _update_health(new_health) -> void:
	health_bar.value = new_health
	health_bar.max_value = max_health

# --------------
# ANIMAÇÃO DE HOVER
# --------------
func _on_button_mouse_entered(button: Button) -> void:
	animate_scale(button, hover_scale)

func _on_button_mouse_exited(button: Button) -> void:
	animate_scale(button, original_scale)

func animate_scale(button: Button, target_scale: Vector2) -> void:
	buttontween = create_tween()
	buttontween.set_ease(tween_type)
	buttontween.set_trans(tween_trans)
	buttontween.tween_property(button, "scale", target_scale, animation_duration)
	buttontween.finished.connect(buttontween.kill)

func setup_main_buttons() -> void:
	# Conecta todos os botões do menu de uma vez
	for button in [start, options, quit]:
		button.pivot_offset = button.size / 2 # Define o pivot para o centro do botão
		button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

func setup_levels_selection() -> void:
	var levelbuttons = level_selection_buttons.find_children("*", "Button", true)
	
	# Conecta todos os botões de seleção de fase de uma vez
	for levelbutton in levelbuttons:
		levelbutton.pivot_offset = levelbutton.size / 2 # Define o pivot para o centro do botão
		levelbutton.mouse_entered.connect(_on_button_mouse_entered.bind(levelbutton))
		levelbutton.mouse_exited.connect(_on_button_mouse_exited.bind(levelbutton))
		levelbutton.pressed.connect(_on_level_pressed.bind(levelbutton))

# --------------
# MAIN MENU
# --------------
func _on_start_pressed() -> void:
	main_menu_canvas.visible = false
	level_selection_canvas.visible = true
	# Configura apenas se ainda não foi feito
	if not levels_setup_done:
		await get_tree().process_frame
		setup_levels_selection()
		levels_setup_done = true

func _on_options_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()

# --------------
# SELEÇÃO DE FASES
# --------------
func _on_back_pressed() -> void:
	main_menu_canvas.visible = true
	level_selection_canvas.visible = false

func _on_level_pressed(button: Button) -> void:
	if GameManager.check_level(int(button.name)): # Pega o número da fase e verifica se ela existe
		GameManager.fade_in(1, func():
			GameManager.load_level(int(button.name)) # Pega o número da fase e tenta carregar
			level_selection_canvas.visible = false
			hud.visible = true
			GameManager.fade_out(0.5)
		)
