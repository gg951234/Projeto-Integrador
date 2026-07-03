extends CanvasLayer

@onready var back: Button = $HBoxContainer/Back
@onready var next: Button = $HBoxContainer/Next
@onready var h_box_container: HBoxContainer = $HBoxContainer

var hover_scale: Vector2 = Vector2(1.1, 1.1)
var animation_duration: float = 0.2
var tween_type: Tween.EaseType = Tween.EASE_OUT
var tween_trans: Tween.TransitionType = Tween.TRANS_BACK

var original_scale: Vector2 = Vector2(1, 1)
var buttontween: Tween

func _ready():
	back.pressed.connect(_on_back_pressed)
	next.pressed.connect(_on_next_pressed)

	# Conecta todos os botões do menu de uma vez
	if h_box_container:
		for button in h_box_container.get_children():
			if not button:
				continue
			button.pivot_offset = button.size / 2 # Define o pivot para o centro do botão
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))

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

func _on_next_pressed():
	if GameManager.check_level(GameManager.currentlevel+1): # Pega o número da fase e verifica se ela existe
		GameManager.fade_in(1, func():
			GameManager.load_level(GameManager.currentlevel+1) # Pega o número da fase e tenta carregar
			queue_free() # Remove a tela de morte
			GameManager.fade_out(0.5)
		)

func _on_back_pressed():
	GameManager.fade_in(0.5, func():
		# Remove a fase atual (LevelRoot)
		GameManager.delete_level()
		
		# Mostra o MainMenuCanvas e esconde outros menus
		var ui = get_tree().root.find_child("UI", true, false)
		if ui:
			var main_menu = ui.find_child("MainMenuCanvas", true, false)
			if main_menu:
				main_menu.visible = true
			
			var level_selection = ui.find_child("LevelSelectionCanvas", true, false)
			if level_selection:
				level_selection.visible = false
		queue_free() # Remove a tela de morte
		GameManager.fade_out(0.5)
	)
