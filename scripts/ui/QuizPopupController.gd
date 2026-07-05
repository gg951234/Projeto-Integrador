extends CanvasLayer

signal quiz_finished(correct: bool)

# Pré-carrega apenas os estilos para o estado "disabled"
var right_disabled_style = preload("res://styles/options_right_style.tres")   # verde
var wrong_disabled_style = preload("res://styles/options_wrong_style.tres") # vermelho

@onready var question_label: Label = $Background/QuestionsContainer/QuestionLabel
@onready var options_container: VBoxContainer = $Background/OptionsContainer
@onready var option_template: Button = $Background/OptionsContainer/Option

var correct_index: int = -1

func _ready():
	process_mode = PROCESS_MODE_ALWAYS

func setup(question: String, options: Array, correct: int):
	question_label.text = question
	correct_index = correct
	print("Resposta Correta: " + str(correct+1) + "ª" + " - " + str(options[correct]))
	
	for child in options_container.get_children():
		child.queue_free()
	
	for i in range(options.size()):
		var btn = option_template.duplicate()
		btn.visible = true
		btn.name = "Option" + str(i)
		btn.text = options[i]
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(300, 45)
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)

func _on_option_pressed(option_index: int):
	# Desabilita todos os botões
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true
	
	# Pega o botão correto (assumindo que a ordem é a mesma)
	var correct_button = options_container.get_child(correct_index) if correct_index >= 0 else null
	
	# Aplica o estilo "certo" no botão correto (sempre verde)
	if correct_button:
		correct_button.add_theme_stylebox_override("disabled", right_disabled_style)
	
	# Se errou, aplica o estilo "errado" em todos os outros botões
	if option_index != correct_index:
		for child in options_container.get_children():
			if child is Button and child != correct_button:
				child.add_theme_stylebox_override("disabled", wrong_disabled_style)
		AudioManager.tocar_sfxglobal("res://assets/sounds/UI/QuizWrongAnswer.mp3")
	else:
		AudioManager.tocar_sfxglobal("res://assets/sounds/UI/QuizRightAnswer.mp3")
	
	await get_tree().create_timer(1).timeout
	
	quiz_finished.emit(option_index == correct_index)
