extends Node2D

## Sistema de orientação por setas usando AStar2D (teoria de grafos).
##
## Constrói um grafo de navegação a partir do(s) TileMapLayer(s) do nível (cada
## célula caminhável = um ponto do AStar2D, conectada às vizinhas ortogonais
## que também são caminháveis). Quando o último inimigo da fase morre, o
## GameManager chama revelar_caminhos(): calculamos o menor caminho do jogador
## até a entrada do boss (mais algumas rotas alternativas) e desenhamos setas
## FIXAS ao longo de cada rota, calculadas uma única vez a partir da posição do
## jogador naquele instante — as setas não se movem mais depois disso.
##
## A rota mais curta (rotas[0]) é desenhada em OURO (caminho certo); as
## alternativas, em AZUL (caminhos errados/mais longos). Enquanto a guia está
## ativa, medimos, quadro a quadro, se o jogador está seguindo a linha dourada —
## se for a maioria do trajeto (>= proporcao_minima_rota_rapida),
## seguiu_majoritariamente_a_rota_mais_rapida() devolve true e o GameManager
## libera a recompensa (moedas) na sala do boss.
##
## Este nó é DIRIGIDO pelo GameManager (que já cuida do ciclo de vida dos
## inimigos e da entrada do boss); ele não conta inimigos por conta própria.
##
## CONFIGURAÇÃO POR FASE (no Inspector do nó, quando os nomes diferem do padrão):
## - tilemap_path: TileMapLayer do chão/paredes (ex: "../TileMap_Terrain" nas 4-8).
## - camadas_extras_de_parede: outras TileMapLayers que também têm parede.

const TEXTURA_SETA := preload("res://assets/images/background/seta.png")
# Limite POR ROTA (não global): com limite global as rotas alternativas, que
# são desenhadas por último, estouravam o orçamento e sumiam no meio do
# caminho. Alto o bastante para não truncar caminhos longos (fases grandes, onde
# o caminho até o boss passa facilmente de 90 setas). Como as setas são fixas
# (criadas uma única vez), o custo é baixo.
const MAX_SETAS_POR_ROTA := 400
const DIRECOES_ORTOGONAIS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const COR_ROTA_RAPIDA := Color(1.0, 0.82, 0.15)          # ouro chamativo (caminho certo)
const COR_ROTA_LENTA := Color(0.55, 0.7, 0.9, 0.7)       # azul neutro (caminhos errados)

# Peso aplicado às células de uma rota já encontrada, para empurrar a busca da
# próxima alternativa por outro corredor SEM desconectar o grafo. Finito: os
# gargalos continuam passáveis, então a alternativa sempre existe em mapas
# conectados (mesmo labirintos tipo "árvore"). Ver _calcular_rotas().
const PESO_ROTA_USADA := 8.0

@export var tilemap_path: NodePath = ^"../TileMapLayer_Terrain"
@export var goal_path: NodePath = ^"../BossEnterArea/Enter"

# Camadas de tiles sobrepostas que TAMBÉM contêm paredes (ex: mapa de Física
# numa segunda TileMapLayer). Uma célula deixa de ser caminhável se qualquer uma
# dessas camadas tiver parede ali — sem isso, as setas passam por dentro de
# paredes que existem só na camada de cima. Vazio = só o tilemap principal.
@export var camadas_extras_de_parede: Array[NodePath] = []

@export var distancia_entre_setas: float = 48.0
@export var rotacao_offset_graus: float = 0.0 # ajuste fino se a arte da seta não apontar pra "direita" por padrão
@export var quantidade_rotas_alternativas: int = 2

# tolerancia_celulas: distância máxima (em passos de corredor, PELO GRAFO) da
# célula do jogador até a LINHA dourada para ainda contar como "no menor caminho".
# Mede pela linha específica e distingue das rotas azuis (ver _construir_faixa_da_rota).
# Maior = mais folga (bom pra corredores largos); menor = mais rígido.
@export var tolerancia_celulas: int = 3
@export var proporcao_minima_rota_rapida: float = 0.5

var astar := AStar2D.new()
var _cell_para_id: Dictionary = {}   # Vector2i -> int
var _id_para_cell: Dictionary = {}   # int -> Vector2i

var tilemap: TileMapLayer
var _camadas_parede: Array[TileMapLayer] = []
var goal: Node2D
var _player: Node2D

var _ativo: bool = false
var _setas: Array[Node2D] = []

# Faixa de células consideradas "seguindo o menor caminho": mais próximas da
# linha DOURADA do que de qualquer rota AZUL, dentro de tolerancia_celulas.
# Usada pelo feedback ao vivo em _process. Recalculada a cada revelação.
var _celulas_perto_do_caminho: Dictionary = {}
var _frames_seguindo_rota_rapida: int = 0
var _frames_total: int = 0
var _ultimo_perto: bool = false

func _ready() -> void:
	# Espera todo mundo da cena terminar o próprio _ready() (player incluso)
	await get_tree().process_frame

	tilemap = get_node_or_null(tilemap_path)
	goal = get_node_or_null(goal_path)
	_player = get_tree().get_first_node_in_group("player")

	if not tilemap:
		push_error("PathGuideManager: TileMapLayer não encontrado em '%s'." % tilemap_path)
		return
	if not goal:
		push_error("PathGuideManager: nó objetivo não encontrado em '%s'." % goal_path)
		return

	_camadas_parede.clear()
	for caminho in camadas_extras_de_parede:
		var camada := get_node_or_null(caminho)
		if camada is TileMapLayer:
			_camadas_parede.append(camada)
		else:
			push_warning("PathGuideManager: camada extra de parede '%s' não é uma TileMapLayer." % caminho)

	_construir_grade()

# O player nunca é assumido como capturado para sempre: qualquer skin/reload
# recria o nó, então sempre revalida e rebusca no grupo antes de usar.
func _obter_player() -> Node2D:
	if not is_instance_valid(_player) or not _player.is_inside_tree():
		_player = get_tree().get_first_node_in_group("player")
	return _player

func _exit_tree() -> void:
	_esconder_setas()

func _process(_delta: float) -> void:
	# Feedback ao vivo: mede, quadro a quadro, se o jogador está seguindo a linha
	# DOURADA (e não uma rota azul) e atualiza o indicador do HUD. A faixa (ver
	# _construir_faixa_da_rota) só contém células mais próximas do ouro que de
	# qualquer rota azul e dentro da tolerância — então em cima de uma seta azul,
	# ou longe de tudo, dá "fora".
	if not _ativo or _celulas_perto_do_caminho.is_empty():
		return
	var jogador := _obter_player()
	if not jogador:
		return

	var cel_jogador := tilemap.local_to_map(tilemap.to_local(jogador.global_position))
	var perto := _celulas_perto_do_caminho.has(cel_jogador)
	_frames_total += 1
	if perto:
		_frames_seguindo_rota_rapida += 1

	if perto != _ultimo_perto:
		_ultimo_perto = perto
		_atualizar_indicador_hud(perto)

# ==================== 🎮 API PÚBLICA (chamada pelo GameManager) ====================
## Libera a guia de caminhos. Chamado quando o último inimigo da fase morre.
func revelar_caminhos() -> void:
	if _ativo:
		return
	if not tilemap or not goal or not _obter_player():
		push_warning("PathGuideManager: não foi possível liberar a guia (tilemap/objetivo/jogador ausente).")
		return
	_ativo = true
	_frames_seguindo_rota_rapida = 0
	_frames_total = 0
	_ultimo_perto = false
	_mostrar_indicador_hud()
	_calcular_e_desenhar_caminhos()

## Interrompe a guia e some com as setas na hora (ex: jogador entrou na sala do boss).
func parar() -> void:
	_parar_guia()

## Permite trocar o destino da guia em tempo real (ex: próximo checkpoint).
func definir_objetivo(novo_objetivo: Node2D) -> void:
	goal = novo_objetivo
	if _ativo:
		_esconder_setas()
		_calcular_e_desenhar_caminhos()

## Diz se o jogador passou a maior parte do trajeto seguindo a linha dourada.
## Chamar ANTES de parar(): base para o GameManager liberar (ou não) a recompensa.
func seguiu_majoritariamente_a_rota_mais_rapida() -> bool:
	if _frames_total == 0:
		return false
	return float(_frames_seguindo_rota_rapida) / float(_frames_total) >= proporcao_minima_rota_rapida

# ==================== 🧭 CONSTRUÇÃO DO GRAFO (AStar2D) ====================
func _construir_grade() -> void:
	var caminhaveis: Dictionary = {} # Vector2i -> true
	var proximo_id := 0

	for celula in tilemap.get_used_cells():
		if _celula_e_caminhavel(celula):
			caminhaveis[celula] = true
			var id := proximo_id
			proximo_id += 1
			_cell_para_id[celula] = id
			_id_para_cell[id] = celula
			astar.add_point(id, tilemap.map_to_local(celula))

	for celula in caminhaveis.keys():
		var id_atual: int = _cell_para_id[celula]
		for direcao in DIRECOES_ORTOGONAIS:
			var vizinha: Vector2i = celula + direcao
			if caminhaveis.has(vizinha):
				var id_vizinha: int = _cell_para_id[vizinha]
				if not astar.are_points_connected(id_atual, id_vizinha):
					astar.connect_points(id_atual, id_vizinha)

func _celula_e_caminhavel(celula: Vector2i) -> bool:
	var dados := tilemap.get_cell_tile_data(celula)
	if dados == null:
		return false
	# Tiles de parede têm polígono de colisão na physics layer 0; chão não tem.
	if dados.get_collision_polygons_count(0) > 0:
		return false
	# Paredes que vivem em camadas sobrepostas também bloqueiam. Todas as camadas
	# compartilham origem e tamanho de célula, então a mesma Vector2i vale pra todas.
	for camada in _camadas_parede:
		var dados_extra := camada.get_cell_tile_data(celula)
		if dados_extra != null and dados_extra.get_collision_polygons_count(0) > 0:
			return false
	return true

# Acha o id do AStar2D mais próximo de uma posição global (procura em raios
# crescentes caso a posição exata caia numa célula não registrada).
func _id_mais_proximo(pos_global: Vector2) -> int:
	var celula_base: Vector2i = tilemap.local_to_map(tilemap.to_local(pos_global))

	if _cell_para_id.has(celula_base):
		return _cell_para_id[celula_base]

	for raio in range(1, 8):
		for dx in range(-raio, raio + 1):
			for dy in range(-raio, raio + 1):
				if maxi(absi(dx), absi(dy)) != raio:
					continue
				var candidata: Vector2i = celula_base + Vector2i(dx, dy)
				if _cell_para_id.has(candidata):
					return _cell_para_id[candidata]

	return -1

# ==================== 🔁 CÁLCULO E ATUALIZAÇÃO DO CAMINHO ====================
# Calcula as rotas UMA vez (setas fixas) e monta a faixa "no menor caminho".
func _calcular_e_desenhar_caminhos() -> void:
	var jogador := _obter_player()
	if not jogador or not is_instance_valid(goal):
		return

	var id_inicio := _id_mais_proximo(jogador.global_position)
	var id_fim := _id_mais_proximo(goal.global_position)

	if id_inicio == -1 or id_fim == -1:
		return

	var rotas := _calcular_rotas(id_inicio, id_fim)
	if rotas.is_empty():
		return

	# Faixa de células "mais perto do OURO que de qualquer rota azul", usada pelo
	# feedback ao vivo em _process() para saber se o jogador segue o menor caminho.
	_construir_faixa_da_rota(rotas)
	_atualizar_setas(rotas)

func _parar_guia() -> void:
	_ativo = false
	_esconder_setas()
	_celulas_perto_do_caminho.clear()
	_esconder_indicador_hud()

# ==================== 🗺️ ROTAS (PRINCIPAL + ALTERNATIVAS) ====================
# Calcula o caminho mais curto e algumas rotas alternativas, ordenado por
# comprimento. Em vez de DESABILITAR o caminho principal (o que desconecta o
# grafo em gargalos, deixando sem alternativa), PENALIZA o peso das células já
# usadas. Assim o A* desvia por corredores paralelos onde é possível, mas ainda
# atravessa os gargalos quando não há outro jeito — gerando rotas alternativas
# COMPLETAS em mapas conectados. Os pesos são sempre restaurados no final.
func _calcular_rotas(id_inicio: int, id_fim: int) -> Array:
	var rotas: Array = []
	var caminhos_ids: Array = []   # id-paths já aceitos, para evitar duplicatas

	var ids_principal := astar.get_id_path(id_inicio, id_fim)
	if ids_principal.size() < 2:
		return rotas

	rotas.append(_rota_de_ids(ids_principal))
	caminhos_ids.append(ids_principal)

	var penalizados: Dictionary = {}   # ids cujo peso foi alterado (a restaurar)
	var ultima_rota := ids_principal

	for i in range(quantidade_rotas_alternativas):
		for id in ultima_rota:
			if id != id_inicio and id != id_fim and not penalizados.has(id):
				penalizados[id] = true
				astar.set_point_weight_scale(id, PESO_ROTA_USADA)

		var ids_alt := astar.get_id_path(id_inicio, id_fim)
		if ids_alt.size() < 2 or _rota_ja_existe(ids_alt, caminhos_ids):
			break # não há mais desvio distinto possível
		rotas.append(_rota_de_ids(ids_alt))
		caminhos_ids.append(ids_alt)
		ultima_rota = ids_alt

	for id in penalizados.keys():
		astar.set_point_weight_scale(id, 1.0)

	rotas.sort_custom(func(a, b): return a["comprimento"] < b["comprimento"])
	return rotas

func _rota_de_ids(ids) -> Dictionary:
	var pontos := _ids_para_pontos(ids)
	return {"pontos": pontos, "comprimento": _comprimento_do_caminho(pontos)}

func _rota_ja_existe(ids, lista: Array) -> bool:
	for outro in lista:
		if ids.size() != outro.size():
			continue
		var igual := true
		for i in range(ids.size()):
			if ids[i] != outro[i]:
				igual = false
				break
		if igual:
			return true
	return false

func _ids_para_pontos(ids) -> PackedVector2Array:
	var pontos: PackedVector2Array = []
	for id in ids:
		var celula: Vector2i = _id_para_cell[id]
		pontos.append(tilemap.to_global(tilemap.map_to_local(celula)))
	return pontos

func _comprimento_do_caminho(pontos: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pontos.size() - 1):
		total += pontos[i].distance_to(pontos[i + 1])
	return total

# ==================== 🎯 FAIXA "NO MENOR CAMINHO" (OURO vs AZUL) ====================
# Faixa de células mais próximas da linha DOURADA (rotas[0]) do que de qualquer
# rota AZUL, dentro de tolerancia_celulas. BFS multi-origem rotulada (Voronoi)
# pelo grafo (respeita paredes): o ouro é semeado primeiro (empates e gargalos
# compartilhados ficam com o ouro), cada célula herda o rótulo da rota mais
# próxima, e só as células OURO entram na faixa. Em cima de uma seta azul, ou
# longe de tudo, a célula fica de fora.
func _construir_faixa_da_rota(rotas: Array) -> void:
	_celulas_perto_do_caminho.clear()
	if rotas.is_empty():
		return

	var eh_ouro: Dictionary = {}   # Vector2i -> bool (rótulo da rota mais próxima)
	var prof: Dictionary = {}      # Vector2i -> int (passos até a rota mais próxima)
	var fila: Array = []

	_semear_rota(rotas[0]["pontos"], true, eh_ouro, prof, fila)
	for i in range(1, rotas.size()):
		_semear_rota(rotas[i]["pontos"], false, eh_ouro, prof, fila)

	var idx := 0
	while idx < fila.size():
		var atual: Vector2i = fila[idx]
		idx += 1
		var p: int = prof[atual]
		if eh_ouro[atual] and p <= tolerancia_celulas:
			_celulas_perto_do_caminho[atual] = true
		if p >= tolerancia_celulas:
			continue
		for dir in DIRECOES_ORTOGONAIS:
			var viz: Vector2i = atual + dir
			if _cell_para_id.has(viz) and not eh_ouro.has(viz):
				eh_ouro[viz] = eh_ouro[atual]
				prof[viz] = p + 1
				fila.append(viz)

# Semeia as células de uma rota (distância 0) com o rótulo dado, sem sobrescrever
# células já semeadas (o ouro é semeado antes, então mantém a prioridade).
func _semear_rota(pontos: PackedVector2Array, ouro: bool, eh_ouro: Dictionary, prof: Dictionary, fila: Array) -> void:
	for ponto in pontos:
		var cel := tilemap.local_to_map(tilemap.to_local(ponto))
		if not eh_ouro.has(cel):
			eh_ouro[cel] = ouro
			prof[cel] = 0
			fila.append(cel)

# ==================== 🏹 SETAS VISUAIS ====================

func _atualizar_setas(rotas: Array) -> void:
	_esconder_setas() # um novo caminho foi calculado — as setas antigas somem

	if rotas.is_empty():
		return

	# rotas já vem ordenado por comprimento crescente (ver _calcular_rotas), então
	# rotas[0] é a MAIS CURTA = caminho certo (ouro, maior). Todas as outras são
	# alternativas mais longas = erradas (azul, menores). Cor por POSIÇÃO (índice),
	# não por comprimento: senão uma alternativa de comprimento parecido com a mais
	# curta também sairia dourada (dois "caminhos certos").
	for i in range(rotas.size()):
		var eh_mais_curta := i == 0
		var cor: Color = COR_ROTA_RAPIDA if eh_mais_curta else COR_ROTA_LENTA
		var escala: float = 1.0 if eh_mais_curta else 0.7
		_desenhar_rota(rotas[i]["pontos"], cor, escala)

func _desenhar_rota(pontos: PackedVector2Array, cor: Color, escala: float) -> void:
	if pontos.size() < 2:
		return

	var segmentos: Array = []
	var comprimento_total := 0.0
	for i in range(pontos.size() - 1):
		var a: Vector2 = pontos[i]
		var b: Vector2 = pontos[i + 1]
		var comprimento := a.distance_to(b)
		segmentos.append({"a": a, "b": b, "comprimento": comprimento, "acumulado": comprimento_total})
		comprimento_total += comprimento

	var setas_nesta_rota := 0
	var distancia := distancia_entre_setas * 0.5 # primeira seta um pouco à frente do jogador
	while distancia < comprimento_total and setas_nesta_rota < MAX_SETAS_POR_ROTA:
		var amostra := _amostrar_caminho(segmentos, distancia)
		_setas.append(_criar_seta(amostra[0], amostra[1], cor, escala))
		setas_nesta_rota += 1
		distancia += distancia_entre_setas

func _amostrar_caminho(segmentos: Array, distancia: float) -> Array:
	for segmento in segmentos:
		if distancia <= segmento["acumulado"] + segmento["comprimento"]:
			var direcao: Vector2 = (segmento["b"] - segmento["a"]).normalized()
			var d_no_segmento: float = distancia - segmento["acumulado"]
			return [segmento["a"] + direcao * d_no_segmento, direcao]

	var ultimo: Dictionary = segmentos[-1]
	return [ultimo["b"], (ultimo["b"] - ultimo["a"]).normalized()]

func _criar_seta(posicao: Vector2, direcao: Vector2, cor: Color, escala: float) -> Sprite2D:
	var seta := Sprite2D.new()
	seta.texture = TEXTURA_SETA
	# z_index 0 (e não 100): mantém as setas no mesmo nível do player, que é
	# y-sorted e sempre está em Y > 0, enquanto este PathGuideManager fica em
	# Y = 0. Assim o player (e demais personagens) desenha POR CIMA das setas, e
	# elas ainda ficam acima do chão por ordem na árvore de nós.
	seta.z_index = 0
	seta.modulate = cor
	seta.scale = Vector2(escala, escala)
	add_child(seta)
	seta.global_position = posicao
	seta.rotation = direcao.angle() + deg_to_rad(rotacao_offset_graus)
	return seta

func _esconder_setas() -> void:
	for seta in _setas:
		if is_instance_valid(seta):
			seta.queue_free()
	_setas.clear()


# ==================== 🖥️ INDICADOR NO HUD ====================

func _obter_hud() -> Node:
	var gm := get_node_or_null(^"/root/GameManager")
	if gm:
		return gm.hud_reference
	return null

func _mostrar_indicador_hud() -> void:
	var hud := _obter_hud()
	if hud and hud.has_method("mostrar_indicador_caminho"):
		hud.mostrar_indicador_caminho(true)
		hud.atualizar_indicador_caminho(false)

func _esconder_indicador_hud() -> void:
	var hud := _obter_hud()
	if hud and hud.has_method("mostrar_indicador_caminho"):
		hud.mostrar_indicador_caminho(false)

func _atualizar_indicador_hud(no_caminho: bool) -> void:
	var hud := _obter_hud()
	if hud and hud.has_method("atualizar_indicador_caminho"):
		hud.atualizar_indicador_caminho(no_caminho)
