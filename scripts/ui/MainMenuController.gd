extends Control

@onready var start: Button = $MainMenuCanvas/Buttons/Start
@onready var options: Button = $MainMenuCanvas/Buttons/Options
@onready var quit: Button = $MainMenuCanvas/Buttons/Quit
@onready var main_menu_canvas: CanvasLayer = $MainMenuCanvas
@onready var level_selection_canvas: CanvasLayer = $LevelSelectionCanvas
@onready var level_selection_buttons: VBoxContainer = $LevelSelectionCanvas/Buttons
@onready var fade_canvas: CanvasLayer = $"../FadeTransition"
@onready var fade_image: ColorRect = $"../FadeTransition/TransitionImage"

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

var original_scale: Vector2 = Vector2(1, 1)
var tween: Tween

var levels_setup_done: bool = false

# --------------
# FUNÇÕES DE INÍCIO (PADRÃO GODOT)
# --------------
func _ready() -> void:  # Executa quando o nó é criado
	# Aguarda um frame para o VBoxContainer ajustar os tamanhos
	await get_tree().process_frame
	setup_main_buttons()

# --------------
# TRANSIÇÕES DE TELA
# --------------
func fade_out(duration: float = 0.5, on_finished: Callable = Callable()) -> void:
	fade_canvas.show()
	tween = create_tween()
	tween.tween_property(fade_image, "modulate:a", 0.0, duration)
	if on_finished:
		tween.finished.connect(on_finished)
	else:
		tween.finished.connect(func(): fade_canvas.hide())

func fade_in(duration: float = 0.5, on_finished: Callable = Callable()) -> void:
	fade_canvas.show()
	fade_image.modulate.a = 0.0  # Começa transparente
	tween = create_tween()
	tween.tween_property(fade_image, "modulate:a", 1.0, duration)
	if on_finished:
		tween.finished.connect(on_finished)
	
# --------------
# ANIMAÇÃO DE HOVER
# --------------
func _on_button_mouse_entered(button: Button) -> void:
	animate_scale(button, hover_scale)

func _on_button_mouse_exited(button: Button) -> void:
	animate_scale(button, original_scale)

func animate_scale(button: Button, target_scale: Vector2) -> void:
	tween = create_tween()
	tween.set_ease(tween_type)
	tween.set_trans(tween_trans)
	tween.tween_property(button, "scale", target_scale, animation_duration)
	tween.finished.connect(tween.kill)

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
# BOTÕES DO MAIN MENU
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
	fade_in(1, func():
		if GameManager.load_level(int(button.name)): # Pega o número da fase e tenta carregar
			level_selection_canvas.visible = false
			fade_out(0.5)
	)
