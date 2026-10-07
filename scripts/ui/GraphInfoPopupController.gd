extends CanvasLayer

## Popup educativa mostrada quando o último inimigo da fase morre (junto com as
## setas do menor caminho). O jogo fica pausado enquanto ela está aberta; quem
## pausa/despausa é o GameManager (ver _mostrar_popup_grafos).
##
## Conteúdo por fase (linguagem de 7º ano):
## - Fases 1-4: teoria de GRAFOS (o labirinto vira um grafo; A* acha o menor caminho).
## - Fases 5-8: CONDICIONAIS (como os jogos "tomam decisões"), uma parte por fase.

signal fechado

const PAGINAS_GRAFOS: Array = [
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

# Da fase 5 em diante, em vez de grafos, mostramos um texto sobre CONDICIONAIS,
# dividido entre as fases 5, 6, 7 e 8 (uma parte por fase).
const PAGINAS_CONDICIONAIS: Dictionary = {
	5: [
		{
			"titulo": "CONDICIONAIS: COMO OS JOGOS DECIDEM",
			"texto": "Quando jogamos um videogame, muitas coisas acontecem automaticamente: um personagem perde vida ao ser atacado, uma porta se abre depois de encontrar uma chave ou um inimigo aparece ao entrar em determinada área.\n\nEssas situações não acontecem por acaso — elas são resultado das CONDICIONAIS, que permitem ao jogo \"tomar decisões\"."
		},
		{
			"titulo": "O QUE SÃO CONDICIONAIS?",
			"texto": "Uma condicional funciona como uma pergunta que o computador faz antes de executar uma ação. A resposta sempre será sim ou não (verdadeiro ou falso). Dependendo dessa resposta, o programa escolhe o que deve acontecer.\n\nUm exemplo do dia a dia: \"Se terminar a lição de casa, poderá brincar.\" Se a condição for verdadeira, a ação acontece; se não, nada muda.\n\nNos jogos, essa lógica é aplicada constantemente, tornando-os mais dinâmicos e inteligentes."
		},
	],
	6: [
		{
			"titulo": "CONDICIONAIS NO LABIRINTO",
			"texto": "No jogo que você está jogando, usamos condicionais em vários momentos:\n\n• MOVIMENTAÇÃO: sempre que o jogador tenta andar, o jogo verifica se há uma parede. Se houver, o personagem não passa; se o caminho estiver livre, ele continua.\n\n• BATALHAS: o jogo verifica se o jogador encostou em um inimigo para iniciar o combate. Depois, confere se o inimigo ainda tem vida — quando chega a zero, ele é derrotado."
		},
		{
			"titulo": "O PORTÃO SECRETO",
			"texto": "Talvez o exemplo mais marcante: o portão só se abre quando TODOS os inimigos foram derrotados. Se ainda restar algum, ele permanece fechado até o jogador cumprir o desafio.\n\nEssas verificações criam regras, desafios e consequências para cada ação. Sem condicionais, tudo aconteceria da mesma forma, sem depender das escolhas do jogador."
		},
	],
	7: [
		{
			"titulo": "ALÉM DOS JOGOS",
			"texto": "As condicionais não estão presentes apenas em videogames. Elas aparecem em aplicativos de celular, sites de compras, caixas eletrônicos e redes sociais.\n\nSempre que um sistema precisa verificar alguma informação antes de agir, existe uma condicional trabalhando nos bastidores."
		},
	],
	8: [
		{
			"titulo": "POR QUE APRENDER SOBRE CONDICIONAIS?",
			"texto": "Entender condicionais é um dos primeiros passos para compreender como a programação funciona. Elas permitem que o computador \"pense\" de maneira organizada, seguindo regras definidas pelo programador.\n\nNo nosso jogo do labirinto, são fundamentais para controlar desafios, impedir ações indevidas e tornar a experiência mais dinâmica e envolvente."
		},
	],
}

@onready var title_label: Label = $Background/TitleLabel
@onready var content_label: Label = $Background/ContentLabel
@onready var page_label: Label = $Background/PageLabel
@onready var back_button: Button = $Background/BackButton
@onready var continue_button: Button = $Background/ContinueButton

var _pagina_atual: int = 0
var _paginas: Array = PAGINAS_GRAFOS


func _ready() -> void:
	# Continua processando com o jogo pausado (mesmo padrão do QuizPopup)
	process_mode = PROCESS_MODE_ALWAYS
	# Da fase 5 em diante, troca o conteúdo de grafos pelo de condicionais.
	var gm = get_node_or_null("/root/GameManager")
	if gm and PAGINAS_CONDICIONAIS.has(gm.currentlevel):
		_paginas = PAGINAS_CONDICIONAIS[gm.currentlevel]
	back_button.pressed.connect(_on_back_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	_mostrar_pagina(0)


func _mostrar_pagina(indice: int) -> void:
	_pagina_atual = indice
	var pagina: Dictionary = _paginas[indice]
	title_label.text = pagina["titulo"]
	content_label.text = pagina["texto"]
	page_label.text = "%d/%d" % [indice + 1, _paginas.size()]
	back_button.visible = indice > 0
	if indice < _paginas.size() - 1:
		continue_button.text = "PRÓXIMO >"
	else:
		continue_button.text = "ENTENDI!"


func _on_back_pressed() -> void:
	if _pagina_atual > 0:
		_mostrar_pagina(_pagina_atual - 1)


func _on_continue_pressed() -> void:
	if _pagina_atual < _paginas.size() - 1:
		_mostrar_pagina(_pagina_atual + 1)
	else:
		fechado.emit()
		queue_free()
