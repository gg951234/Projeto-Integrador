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
const COR_ROTA_LENTA := Color(0.4, 0.68, 1.0, 0.85)      # azul claro visível (caminhos errados)

# Peso aplicado às células de uma rota já encontrada, para empurrar a busca da
# próxima alternativa por outro corredor SEM desconectar o grafo. Finito: os
# gargalos continuam passáveis, então a alternativa sempre existe em mapas
# conectados (mesmo labirintos tipo "árvore"). Ver _calcular_rotas().
const PESO_ROTA_USADA := 8.0

@export var tilemap_path: NodePath = ^"../TileMapLayer_Terrain"
@export var goal_path: NodePath = ^"../BossEnterArea/Enter"

# (Obsoleto) Antes marcava camadas extras de parede tile a tile. Agora a
# caminhabilidade é medida pela FÍSICA real (a colisão do jogador), que já
# enxerga TODAS as camadas de tile e StaticBodies de parede. Mantido só para não
# quebrar cenas que ainda setam este campo.
@export var camadas_extras_de_parede: Array[NodePath] = []

# Layer de colisão das paredes. O TileSet usa a physics layer 0 (= máscara 1).
@export var mascara_paredes: int = 1

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
var _pos_mundo_da_celula: Dictionary = {} # Vector2i -> Vector2 (ponto LIVRE, onde o player cabe; é ali que a seta é desenhada)

var tilemap: TileMapLayer
var goal: Node2D
var _player: Node2D

var _ativo: bool = false
var _setas: Array[Node2D] = []

# Ponto de partida da guia (setas FIXAS): a posição do ÚLTIMO inimigo morto,
# passada pelo GameManager em revelar_caminhos(). Não muda depois de revelada.
var _origem_guia: Vector2 = Vector2.ZERO

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

	# Espera um quadro de física para os corpos de colisão do(s) tilemap(s) e das
	# paredes já existirem antes de sondar a caminhabilidade pela física.
	await get_tree().physics_frame

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
## origem_global: de onde a linha parte — a posição do último inimigo morto,
## passada pelo GameManager. Se não vier, usa a posição atual do jogador.
func revelar_caminhos(origem_global = null) -> void:
	if _ativo:
		return
	if not tilemap or not goal or not _obter_player():
		push_warning("PathGuideManager: não foi possível liberar a guia (tilemap/objetivo/jogador ausente).")
		return
	_ativo = true
	if origem_global is Vector2:
		_origem_guia = origem_global
	else:
		_origem_guia = _obter_player().global_position
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
# A caminhabilidade é medida pela FÍSICA real: uma célula é nó do grafo se o
# corpo do jogador couber em ALGUMA posição dentro dela. Isso resolve dois
# problemas do teste tile-a-tile antigo:
#   1) Paredes com colisão PARCIAL (meias-paredes/beiradas) não fragmentam mais o
#      grafo — as passagens estreitas por onde o jogador realmente passa ficam
#      conectadas, então sempre existe rota do inimigo até o boss.
#   2) As paredes de QUALQUER camada de tile (Terrain, Terrain2, ...) e quaisquer
#      StaticBodies bloqueiam de verdade — as setas não as atravessam.
func _construir_grade() -> void:
	var space := tilemap.get_world_2d().direct_space_state
	if space == null:
		return

	var forma := _forma_do_agente()
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = forma
	consulta.collision_mask = mascara_paredes
	consulta.collide_with_areas = false
	consulta.collide_with_bodies = true
	consulta.exclude = _corpos_a_ignorar()
	var amostras := _amostras_na_celula(forma.size)

	var caminhaveis: Dictionary = {} # Vector2i -> true
	var proximo_id := 0

	# 1) Nós: cada célula onde o player cabe. Guarda a posição LIVRE (mais perto do
	#    centro) — é ali que a seta será desenhada, então ela nunca fica em cima da
	#    parede, mesmo quando o player só passa pela beirada da célula.
	for celula in tilemap.get_used_cells():
		var pos_livre = _posicao_livre_na_celula(celula, space, consulta, amostras)
		if pos_livre != null:
			caminhaveis[celula] = true
			_pos_mundo_da_celula[celula] = pos_livre
			var id := proximo_id
			proximo_id += 1
			_cell_para_id[celula] = id
			_id_para_cell[id] = celula
			astar.add_point(id, tilemap.to_local(pos_livre))

	# 2) Arestas: só liga vizinhas se o player consegue de fato PASSAR entre elas
	#    (o corpo cabe no meio do caminho). Sem isso, a linha ligava células
	#    separadas por uma parede fina e as setas a atravessavam.
	for celula in caminhaveis.keys():
		var id_atual: int = _cell_para_id[celula]
		var pos_atual: Vector2 = _pos_mundo_da_celula[celula]
		for direcao in DIRECOES_ORTOGONAIS:
			var vizinha: Vector2i = celula + direcao
			if caminhaveis.has(vizinha):
				var id_vizinha: int = _cell_para_id[vizinha]
				if not astar.are_points_connected(id_atual, id_vizinha):
					if _passagem_livre(pos_atual, _pos_mundo_da_celula[vizinha], space, consulta):
						astar.connect_points(id_atual, id_vizinha)

# Devolve a posição LIVRE dentro da célula (a mais próxima do centro onde o corpo
# do player não bate em parede), ou null se a célula for parede de verdade.
func _posicao_livre_na_celula(celula: Vector2i, space: PhysicsDirectSpaceState2D, consulta: PhysicsShapeQueryParameters2D, amostras: Array):
	var centro := tilemap.to_global(tilemap.map_to_local(celula))
	for deslocamento in amostras:
		consulta.transform = Transform2D(0.0, centro + deslocamento)
		if space.intersect_shape(consulta, 1).is_empty():
			return centro + deslocamento
	return null

# Player consegue passar de a para b? Testa o corpo no meio do trajeto.
func _passagem_livre(a: Vector2, b: Vector2, space: PhysicsDirectSpaceState2D, consulta: PhysicsShapeQueryParameters2D) -> bool:
	consulta.transform = Transform2D(0.0, (a + b) * 0.5)
	return space.intersect_shape(consulta, 1).is_empty()

# Forma que aproxima o corpo do jogador (retângulo da CollisionShape2D dele, já
# em escala de mundo), levemente encolhida pra não "raspar" nas bordas.
func _forma_do_agente() -> RectangleShape2D:
	var forma := RectangleShape2D.new()
	forma.size = Vector2(56, 11) # padrão ~ colisão do player (14 x 2.75 * escala 4)
	var jogador := _obter_player()
	if jogador:
		var cs = jogador.find_child("CollisionShape2D", true, false)
		if cs is CollisionShape2D and (cs as CollisionShape2D).shape is RectangleShape2D:
			var r := (cs as CollisionShape2D).shape as RectangleShape2D
			forma.size = r.size * (cs as CollisionShape2D).global_scale.abs()
	forma.size = Vector2(maxf(forma.size.x - 2.0, 2.0), maxf(forma.size.y - 2.0, 2.0))
	return forma

# Corpos ignorados na sondagem: a Porta e a Barreira do boss (fecham a entrada,
# mas ABREM quando a guia aparece — senão o objetivo fica isolado do grafo) e o
# próprio jogador.
func _corpos_a_ignorar() -> Array[RID]:
	var ignora: Array[RID] = []
	var jogador := _obter_player()
	if jogador is CollisionObject2D:
		ignora.append((jogador as CollisionObject2D).get_rid())
	var area_boss := goal.get_parent()
	if area_boss:
		for corpo in area_boss.find_children("*", "CollisionObject2D", true, false):
			ignora.append((corpo as CollisionObject2D).get_rid())
	return ignora

# Posições (relativas ao centro da célula) onde testar o corpo do agente: ele
# pode se encaixar fora do centro, sobretudo na vertical (é baixo). Grid 3x5
# limitado pela folga (célula - agente)/2.
func _amostras_na_celula(agente: Vector2) -> Array:
	var celula := Vector2(tilemap.tile_set.tile_size) * tilemap.global_scale.abs()
	var folga_x := maxf((celula.x - agente.x) * 0.5, 0.0)
	var folga_y := maxf((celula.y - agente.y) * 0.5, 0.0)
	var xs := [-folga_x, 0.0, folga_x] if folga_x > 1.0 else [0.0]
	var ys := [-folga_y, -folga_y * 0.5, 0.0, folga_y * 0.5, folga_y] if folga_y > 1.0 else [0.0]
	var amostras: Array = []
	for x in xs:
		for y in ys:
			amostras.append(Vector2(x, y))
	# centro primeiro: assim a posição LIVRE escolhida é a mais próxima do centro.
	amostras.sort_custom(func(p, q): return p.length_squared() < q.length_squared())
	return amostras

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
	if not _obter_player() or not is_instance_valid(goal):
		return

	var id_inicio := _id_mais_proximo(_origem_guia)
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
		# posição LIVRE da célula (onde o player cabe), não o centro cru — assim a
		# seta é desenhada no espaço navegável, não em cima da parede.
		pontos.append(_pos_mundo_da_celula.get(celula, tilemap.to_global(tilemap.map_to_local(celula))))
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
		var escala: float = 1.0 if eh_mais_curta else 0.6
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
