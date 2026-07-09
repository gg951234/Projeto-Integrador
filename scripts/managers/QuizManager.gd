extends Node

signal quiz_result(correct: bool)

var used_questions = {}
var current_level = ""
var current_question_index = -1
var quiz_ui = null

func _ready():
	randomize()  # garante aleatoriedade

func reset():
	used_questions.clear()

# Retorna uma pergunta aleatória de um nível, garantindo não repetição
func get_random_question(level: String) -> Dictionary:
	if not QuizData.questions.has(level):
		push_error("Nível '%s' não encontrado no QuizData." % level)
		return {}
	
	var pool = QuizData.questions[level]
	var total = pool.size()
	if total == 0:
		return {}
	
	if not used_questions.has(level):
		used_questions[level] = []
	
	var used = used_questions[level]
	if used.size() >= total:
		used.clear()
	
	var available = []
	for i in range(total):
		if not i in used:
			available.append(i)
	
	if available.is_empty():
		used.clear()
		available = range(total)
	
	var idx = available[randi() % available.size()]
	used.append(idx)
	current_level = level
	current_question_index = idx
	return pool[idx]

# Abre a tela de quiz para um determinado nível
func show_quiz(level: String) -> void:
	var data = get_random_question(level)
	if data.is_empty():
		quiz_result.emit(false)
		return
	
	# Embaralha as opções
	var shuffled_options = data.options.duplicate()
	shuffled_options.shuffle()
	
	# Descobre o índice da resposta correta nas opções embaralhadas
	var correct_answer = data.correct  # string
	var correct_index = shuffled_options.find(correct_answer)
	if correct_index == -1:
		push_error("Resposta correta '%s' não encontrada nas opções embaralhadas!" % correct_answer)
		quiz_result.emit(false)
		return
	
	# Instancia a cena do quiz
	var quiz_scene = preload("res://scenes/UI/quiz_popup.tscn")
	quiz_ui = quiz_scene.instantiate()
	get_tree().root.add_child(quiz_ui)
	quiz_ui.setup(data.question, shuffled_options, correct_index)
	quiz_ui.quiz_finished.connect(_on_quiz_finished, CONNECT_ONE_SHOT)

func _on_quiz_finished(correct: bool):
	if quiz_ui:
		quiz_ui.queue_free()
		quiz_ui = null
	quiz_result.emit(correct)
