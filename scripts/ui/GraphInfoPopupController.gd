extends CanvasLayer

## Popup educativa sobre teoria de grafos, mostrada quando o último inimigo da
## fase morre (junto com as setas do menor caminho). Conteúdo em linguagem de
## 7º ano, baseado na abordagem "Labirintos 2D como grafos": o labirinto vira
## um grafo (encruzilhadas = vértices, corredores = arestas) e um algoritmo de
## busca (A*) encontra o menor caminho. O jogo fica pausado enquanto ela está
## aberta; quem pausa/despausa é o GameManager (ver _mostrar_popup_grafos).

signal fechado

const PAGINAS: Array = [
	{
		"titulo": "O QUE É UM GRAFO?",
		"texto": "Um grafo é um desenho feito de PONTOS e LINHAS.\n\nOs pontos se chamam VÉRTICES e as linhas que ligam um ponto ao outro se chamam ARESTAS.\n\nPense no mapa do metrô: cada estação é um vértice, e o trilho entre duas estações é uma aresta!"
	},
	{
		"titulo": "O LABIRINTO VIROU UM GRAFO",
		"texto": "Dá para transformar este labirinto em um grafo!\n\nCada encruzilhada (lugar onde você escolhe para onde ir) vira um VÉRTICE, e cada corredor vira uma ARESTA.\n\nAndar pelo labirinto é o mesmo que passear pelo grafo, pulando de vértice em vértice."
	},
	{
		"titulo": "O MENOR CAMINHO",
		"texto": "Entre todos os caminhos até a saída, sempre existe um MENOR CAMINHO.\n\nO computador descobre qual é usando um algoritmo de busca chamado A* (lê-se \"A-estrela\"): ele testa as rotas do grafo e escolhe a mais curta.\n\nÉ assim que o GPS acha a melhor rota até a sua casa!"
	},
	{
		"titulo": "SEU DESAFIO",
		"texto": "As setas DOURADAS mostram o menor caminho até o chefe.\nAs setas AZUIS mostram caminhos mais longos.\n\nSiga o caminho dourado na maior parte do trajeto e ganhe 5 MOEDAS de recompensa na sala do chefe.\n\nBoa sorte!"
	},
]

@onready var title_label: Label = $Background/TitleLabel
@onready var content_label: Label = $Background/ContentLabel
@onready var page_label: Label = $Background/PageLabel
@onready var back_button: Button = $Background/BackButton
@onready var continue_button: Button = $Background/ContinueButton

var _pagina_atual: int = 0


func _ready() -> void:
	# Continua processando com o jogo pausado (mesmo padrão do QuizPopup)
	process_mode = PROCESS_MODE_ALWAYS
	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	_mostrar_pagina(0)


func _mostrar_pagina(indice: int) -> void:
	_pagina_atual = indice
	var pagina: Dictionary = PAGINAS[indice]
	title_label.text = pagina["titulo"]
	content_label.text = pagina["texto"]
	page_label.text = "%d/%d" % [indice + 1, PAGINAS.size()]
	back_button.visible = indice > 0
	if indice < PAGINAS.size() - 1:
		continue_button.text = "PRÓXIMO >"
	else:
		continue_button.text = "ENTENDI!"


func _on_back_pressed() -> void:
	if _pagina_atual > 0:
		_mostrar_pagina(_pagina_atual - 1)


func _on_continue_pressed() -> void:
	if _pagina_atual < PAGINAS.size() - 1:
		_mostrar_pagina(_pagina_atual + 1)
	else:
		fechado.emit()
		queue_free()
