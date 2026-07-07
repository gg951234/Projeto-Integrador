extends Node2D

## Sistema de orientação por setas usando AStar2D (teoria de grafos).
##
## Constrói um grafo de navegação a partir do TileMapLayer do nível (cada
## célula caminhável = um ponto do AStar2D, conectada às vizinhas ortogonais
## que também são caminháveis). Quando o último inimigo da fase morre, o
## GameManager chama revelar_caminhos(): calculamos o menor caminho do jogador
## até a entrada do boss (mais algumas rotas alternativas) e desenhamos setas
## FIXAS ao longo de cada rota, calculadas uma única vez a partir da posição do
## jogador naquele instante — as setas não se movem mais depois disso.
##
## A rota mais curta é desenhada numa cor chamativa; as alternativas, numa cor
## neutra mais apagada (mas ainda visível). Enquanto a guia está ativa, medimos,
## quadro a quadro, quanto tempo o jogador passa perto o suficiente da rota mais
## curta — se for a maioria do trajeto (>= proporcao_minima_rota_rapida),
## seguiu_majoritariamente_a_rota_mais_rapida() devolve true e o GameManager
## libera a recompensa (moedas) na sala do boss.
##
## Este nó é DIRIGIDO pelo GameManager (que já cuida do ciclo de vida dos
## inimigos e da entrada do boss); ele não conta inimigos por conta própria.

const TEXTURA_SETA := preload("res://assets/images/background/seta.png")
# Limite POR ROTA (não global): com limite global as rotas alternativas, que
# são desenhadas por último, estouravam o orçamento e sumiam no meio do
# caminho. Como as setas são fixas (criadas uma única vez), o custo é baixo.
const MAX_SETAS_POR_ROTA := 90
const DIRECOES_ORTOGONAIS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# Gradiente de cor por velocidade da rota: a mais rápida (menor comprimento)
# fica na cor mais chamativa; as mais longas ficam progressivamente mais
# claras/apagadas, mas ainda bem visíveis — ver _atualizar_setas().
const COR_ROTA_RAPIDA := Color(1.0, 0.82, 0.15)          # amarelo-ouro chamativo
const COR_ROTA_LENTA := Color(0.55, 0.7, 0.9, 0.7)       # azul-acinzentado neutro, mas visível

@export var tilemap_path: NodePath = ^"../TileMapLayer_Terrain"
@export var goal_path: NodePath = ^"../BossEnterArea/Enter"

@export var distancia_entre_setas: float = 48.0
@export var rotacao_offset_graus: float = 0.0 # ajuste fino se a arte da seta não apontar pra "direita" por padrão
@export var quantidade_rotas_alternativas: int = 2

# Usados pra saber, no fim, se o jogador seguiu majoritariamente a rota mais
# rápida (libera a recompensa) — ver seguiu_majoritariamente_a_rota_mais_rapida().
@export var tolerancia_seguir_rota: float = 90.0
@export var proporcao_minima_rota_rapida: float = 0.5

var astar := AStar2D.new()
var _cell_para_id: Dictionary = {}   # Vector2i -> int
var _id_para_cell: Dictionary = {}   # int -> Vector2i

var tilemap: TileMapLayer
var goal: Node2D
var _player: Node2D

var _ativo: bool = false
var _setas: Array[Node2D] = []

# Rota mais curta atual (cacheada) usada pelo feedback ao vivo em _process().
var _rota_rapida_pontos: PackedVector2Array = PackedVector2Array()
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
	# Feedback ao vivo: mede, quadro a quadro, se o jogador está perto o
	# suficiente da rota mais curta e atualiza o indicador do HUD. A estatística
	# acumulada aqui é o que seguiu_majoritariamente_a_rota_mais_rapida() usa.
	if not _ativo or _rota_rapida_pontos.size() < 2:
		return
	var jogador := _obter_player()
	if not jogador:
		return

	var perto := _distancia_ate_polilinha(jogador.global_position, _rota_rapida_pontos) <= tolerancia_seguir_rota
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


## Diz se o jogador passou a maior parte do trajeto perto o suficiente da rota
## mais curta. Não rastreia a rota que ele realmente andou — só o quão perto ele
## estava da rota rápida, quadro a quadro. Chamar ANTES de parar(): é a base
## para o GameManager liberar (ou não) a recompensa de moedas na sala do boss.
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
	return dados.get_collision_polygons_count(0) == 0


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

# Calcula as rotas UMA vez, a partir da posição do jogador no instante em que o
# último inimigo morre, e desenha as setas fixas. Daí em diante as setas não se
# movem — só o indicador do HUD acompanha, ao vivo, se o jogador está ou não
# sobre a rota mais curta (ver _process).
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

	# rotas vem ordenado por comprimento crescente; a [0] é a mais curta. Ela é
	# cacheada para o feedback ao vivo (indicador do HUD) em _process().
	_rota_rapida_pontos = rotas[0]["pontos"]
	_atualizar_setas(rotas)


func _parar_guia() -> void:
	_ativo = false
	_esconder_setas()
	_rota_rapida_pontos = PackedVector2Array()
	_esconder_indicador_hud()


# ==================== 🗺️ ROTAS (PRINCIPAL + ALTERNATIVAS) ====================

# Calcula o caminho mais curto e, opcionalmente, algumas rotas alternativas,
# devolvendo tudo ordenado por comprimento (a mais rápida primeiro). Cada
# alternativa é achada bloqueando temporariamente os pontos já usados pelas
# rotas anteriores (menos início/fim) e recalculando — isso força a busca a
# desviar por outro corredor do labirinto em vez de repetir a mesma rota. Os
# pontos são sempre restaurados no final.
func _calcular_rotas(id_inicio: int, id_fim: int) -> Array:
	var rotas: Array = []

	var ids_principal := astar.get_id_path(id_inicio, id_fim)
	if ids_principal.size() < 2:
		return rotas

	var pontos_principal := _ids_para_pontos(ids_principal)
	rotas.append({"pontos": pontos_principal, "comprimento": _comprimento_do_caminho(pontos_principal)})

	var pontos_bloqueados: Array = []
	var ultima_rota := ids_principal

	for i in range(quantidade_rotas_alternativas):
		for id in ultima_rota:
			if id != id_inicio and id != id_fim and not pontos_bloqueados.has(id):
				pontos_bloqueados.append(id)
				astar.set_point_disabled(id, true)

		var ids_alternativa := astar.get_id_path(id_inicio, id_fim)
		if ids_alternativa.size() < 2:
			break # não existe mais nenhum desvio possível
		var pontos_alt := _ids_para_pontos(ids_alternativa)
		rotas.append({"pontos": pontos_alt, "comprimento": _comprimento_do_caminho(pontos_alt)})
		ultima_rota = ids_alternativa

	for id in pontos_bloqueados:
		astar.set_point_disabled(id, false)

	rotas.sort_custom(func(a, b): return a["comprimento"] < b["comprimento"])
	return rotas


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


func _distancia_ate_polilinha(ponto: Vector2, pontos: PackedVector2Array) -> float:
	if pontos.size() < 2:
		return INF
	var menor := INF
	for i in range(pontos.size() - 1):
		var mais_proximo: Vector2 = Geometry2D.get_closest_point_to_segment(ponto, pontos[i], pontos[i + 1])
		menor = minf(menor, ponto.distance_to(mais_proximo))
	return menor


# ==================== 🏹 SETAS VISUAIS ====================

func _atualizar_setas(rotas: Array) -> void:
	_esconder_setas() # um novo caminho foi calculado — as setas antigas somem

	if rotas.is_empty():
		return

	# rotas já vem ordenado por comprimento crescente (ver _calcular_rotas).
	# A mais curta sai maior e na cor chamativa; as alternativas, menores e na
	# cor neutra — todas desenhadas por inteiro (limite de setas é por rota).
	var comprimento_min: float = rotas[0]["comprimento"]
	var comprimento_max: float = rotas[-1]["comprimento"]
	var intervalo: float = comprimento_max - comprimento_min

	for rota in rotas:
		var t := 0.0
		if intervalo > 0.001:
			t = (rota["comprimento"] - comprimento_min) / intervalo
		var cor: Color = COR_ROTA_RAPIDA.lerp(COR_ROTA_LENTA, t)
		var escala: float = lerpf(1.0, 0.7, t)
		_desenhar_rota(rota["pontos"], cor, escala)


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
	seta.z_index = 100
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
