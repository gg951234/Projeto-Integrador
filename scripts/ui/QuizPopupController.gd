extends CanvasLayer

signal quiz_finished(correct: bool)

@onready var question_label: Label = $Background/QuestionsContainer/QuestionLabel
@onready var options_container: VBoxContainer = $Background/OptionsContainer

var correct_index: int = -1

func _ready():
	# Permite que a UI processe mesmo com o jogo pausado
	process_mode = PROCESS_MODE_ALWAYS

func setup(question: String, options: Array, correct: int):
	question_label.text = question
	correct_index = correct
	print("Resposta Correta: " + str(correct+1) + "ª" + " - " + str(options[correct]))
	
	for child in options_container.get_children():
		child.queue_free()
	
	for i in range(options.size()):
		var btn = Button.new()
		btn.text = options[i]
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.custom_minimum_size = Vector2(300, 45)
		btn.pressed.connect(_on_option_pressed.bind(i))
		options_container.add_child(btn)

func _on_option_pressed(option_index: int):
	quiz_finished.emit(option_index == correct_index)
