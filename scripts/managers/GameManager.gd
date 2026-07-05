extends Node

# Dados que não precisam ser salvos
var currentlevel: int = 1
var gamescore: int = 0
var currentlevelroot: Node = null
var currentlevelpath: String = ""
var enemies_remaining: int = 0
var enemies_max: int = 0
var door_node: Node = null

# Dados para serem salvos
var playername: String = ""
var currenttimer: int = 0
var currentscore: int = 0
var currentcoins: int = 0
var unlockedlevels: Array = [1, 2]

# Sistema de transição global
var ui_reference: Control
var hud_reference: CanvasLayer
var transition_layer: CanvasLayer
var transition_rect: ColorRect

# Timer para contagem de tempo
var timer: Timer

func _ready() -> void:
	await get_tree().process_frame
	# ADD FUNÇÃO PARA CARREGAR DADOS DO BANCO DE DADOS
	currentlevelroot = get_tree().root.find_child("LevelRoot", true, false)
	
	# Cria o sistema de transição global (sempre visível, mas transparente)
	_find_nodes()
	_create_transition_system()
	
	# Cria e configura o timer de contagem
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	
	AudioManager.tocar_musica("res://assets/sounds/UI/Menu SoundTrack - Moment of Peace.mp3")

# --------------
# TIMER DE CONTAGEM
# --------------
func _on_timer_timeout() -> void:
	currenttimer += 1
	if hud_reference and hud_reference.has_method("_update_timer"):
		hud_reference._update_timer(currenttimer)

# --------------
# TRANSIÇÕES DE TELA
# --------------
func _find_nodes() -> void:
	# Procura por um CanvasLayer chamado "FadeTransition" em qualquer lugar da cena root
	var root = get_tree().root
	ui_reference = root.find_child("UI", true, false)
	if ui_reference:
		hud_reference = ui_reference.find_child("HUD")
		if not hud_reference:
			push_error("HUD não existe")
	else:
		push_error("Referência para UI não encontrada")
	
	transition_layer = root.find_child("FadeTransition", true, false)
	
	if transition_layer:
		transition_rect = transition_layer.find_child("TransitionImage", true, false)
		if transition_rect:
			# Garante que ela comece escondida e transparente
			transition_layer.hide()
			transition_rect.modulate.a = 0.0
		else:
			push_error("FadeTransition encontrada, mas não achei o TransitionImage")
	else:
		push_error("Não encontrou uma FadeTransition na árvore. Verifique se ela existe como filha da root.")

func _create_transition_system() -> void:
	# Ajusta o tamanho quando a janela for redimensionada (opcional)
	get_tree().root.connect("size_changed", _on_viewport_size_changed)

func _on_viewport_size_changed() -> void:
	if transition_rect:
		transition_rect.size = get_tree().root.size

# Funções de fade globais
func fade_in(duration: float = 0.5, on_finished: Callable = Callable()) -> void:
	transition_layer.show()
	transition_rect.modulate.a = 0.0  # Começa transparente
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 1.0, duration)
	if on_finished:
		tween.finished.connect(on_finished)

func fade_out(duration: float = 0.5, on_finished: Callable = Callable()) -> void:
	transition_layer.show()
	var tween = create_tween()
	tween.tween_property(transition_rect, "modulate:a", 0.0, duration)
	if on_finished:
		transition_layer.hide()
		tween.finished.connect(on_finished)

# --------------
# SISTEMA DE FASES
# --------------
func check_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
	
	if fase_desbloqueada(levelnumber):
		# Achar o caminho da fase se o player tiver ela desbloqueada
		currentlevelpath = "res://scenes/levels/level_%s.tscn" % levelnumber
		# Retornar true se ela existir
		if ResourceLoader.exists(currentlevelpath):
			return 1
		else:
			print("A fase " + str(levelnumber) + " não existe")
	else:
		print("O jogador ainda não desbloqueou a fase " + str(levelnumber))
	
	return 0

func fase_desbloqueada(numero: int) -> bool:
	if numero <= 1:
		return true
	var fase_anterior = fase_id(numero - 1)
	return PlayerData.progresso_fases.get(fase_anterior, {}).get("completada", false)

func delete_level() -> bool:
	if currentlevelroot:
		currentlevelroot.queue_free()
		currentcoins = 0
		currentscore = 0
		enemies_remaining = 0
		return 1
	return 0

func load_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		levelnumber = currentlevel

	delete_level()
	
	if check_level(levelnumber):
		print(currentlevelpath)
		currentlevelroot = load(currentlevelpath).instantiate()
		add_child(currentlevelroot)
		currentlevelroot.name = "LevelRoot"
		print("Fase " + str(levelnumber) + " carregada")

		var player = currentlevelroot.get_node("Player")
		hud_reference.set_player(player)
		hud_reference.show()
		
		# Inicia o timer e zera o contador
		currenttimer = 0
		timer.start()
		
		# Conecta o sinal de morte do player para parar o timer
		if player.has_signal("died") and not player.died.is_connected(_on_player_died):
			player.died.connect(_on_player_died)
		
		# Busca o nó Enemies recursivamente (não precisa ser filho direto)
		var enemies_node = currentlevelroot.find_child("Enemies", true, false)
		if enemies_node and enemies_node.has_method("spawn_enemies"):
			# Passa o nome do nível como string (ex: "Level1")
			enemies_node.spawn_enemies("Level" + str(levelnumber))
			# Configura a contagem e conecta os sinais
			_setup_enemy_counting(enemies_node)
		else:
			push_error("Nó 'Enemies' não encontrado ou não possui o método spawn_enemies")
			# Opcional: imprime a árvore para depuração
			print("Estrutura do LevelRoot:")

		# Configuração da câmera
		var camera = player.get_node("PlayerCamera")
		if camera:
			CameraManager.set_camera(camera)
		else:
			push_warning("Camera2D não encontrada no Player.")

		var level_name = "Level" + str(levelnumber)
		CameraManager.set_limits_from_level(level_name, 0.0)
		
		AudioManager.tocar_musica(CameraData.get_soundtrack(level_name))
		
		setup_boss_enter_area()
		currentlevel = levelnumber
		return true
	else:
		print("Falha ao carregar a fase " + str(levelnumber))
		return false

# Identificador da fase usado no Firestore ("fase_01", "fase_02", ...)
func fase_id(numero: int = 0) -> String:
	if numero <= 0:
		numero = currentlevel
	return "fase_%02d" % numero

func level_completed() -> bool:
	# Para o timer quando a fase é completada
	timer.stop()
	AudioManager.tocar_musica("res://assets/sounds/UI/Menu SoundTrack - Moment of Peace.mp3")
	
	# Esperar para ver a animação do boss sendo derrotado
	await get_tree().create_timer(2).timeout
	
	# Enviar para o banco de dados
	var fid := fase_id(currentlevel)
	
	var eh_novo_recorde: bool = PlayerData.registrar_fim_de_fase(fid, currentcoins, currenttimer, currentscore)
	if eh_novo_recorde:
		FirebaseManager.enviar_ranking_da_fase(fid, currentscore, currenttimer)
	
	unlocknextlevel()
	hud_reference.hide()
	
	GameManager.fade_in(0.5, func():
		var victory_screen = load("res://scenes/UI/victory_screen.tscn").instantiate()
		get_tree().root.add_child(victory_screen)
		victory_screen.updatestats(currenttimer, currentscore, currentcoins)
		GameManager.fade_out(0.5)
	)
	return 1

# --------------
# ÁREA DE ENTRADA DO BOSS
# --------------
func setup_boss_enter_area() -> void:
	if not currentlevelroot:
		return
	
	var boss_enter_area = currentlevelroot.get_node("BossEnterArea")
	if not boss_enter_area:
		# Não há área de entrada do boss neste nível, ignorar
		return
	
	# Armazena a referência da Door, se existir
	door_node = boss_enter_area.get_node("Door") if boss_enter_area.has_node("Door") else null
	
	var enter_area = boss_enter_area.get_node("Enter")
	var barrier = boss_enter_area.get_node("Barrier")
	
	if enter_area and barrier:
		# Conecta o sinal body_entered da Enter para ativar a Barrier
		if not enter_area.body_entered.is_connected(_on_boss_enter_area_body_entered):
			enter_area.body_entered.connect(_on_boss_enter_area_body_entered.bind(barrier))
	else:
		push_warning("BossEnterArea não possui os nós 'Enter' e/ou 'Barrier'.")

func _on_boss_enter_area_body_entered(body: Node, barrier: Node) -> void:
	if body.is_in_group("player"):
		# Ativa a barreira (torna colidível)
		if barrier is StaticBody2D and barrier.get_node("CollisionShape2D"):
			var collisionshape = barrier.get_node("CollisionShape2D")
			collisionshape.set_deferred("disabled", false)
		
		# Opcional: mudar limites da câmera para a sala do boss
		var bossroom_name = "BossRoom" + str(currentlevel)
		CameraManager.set_camera_to_room(bossroom_name, 0, "fill")
		
		AudioManager.tocar_musica(CameraData.get_soundtrack(bossroom_name))
		
		# Desconecta o sinal para não disparar novamente
		var enter_area = barrier.get_parent().get_node("Enter")
		if enter_area and enter_area.body_entered.is_connected(_on_boss_enter_area_body_entered):
			enter_area.body_entered.disconnect(_on_boss_enter_area_body_entered)

func unlocknextlevel() -> void:
	if not (currentlevel + 1) in unlockedlevels:
		unlockedlevels.append(currentlevel+1)

# --------------
# SISTEMA DE COLETA
# --------------
func add_coins() -> void:
	currentcoins += 1
	hud_reference._update_coins(currentcoins)

func add_score(amount: int) -> void:
	currentscore += amount
	print("Score: ", currentscore)

# --------------
# CONTAGEM DE INIMIGOS E PORTA
# --------------
func _setup_enemy_counting(enemies_node: Node) -> void:
	# Coleta todos os filhos que estão no grupo "enemy"
	var enemies = enemies_node.get_children().filter(func(child):
		return child.is_in_group("enemy")
	)
	enemies_max = enemies.size()
	enemies_remaining = enemies.size()
	hud_reference._update_enemies_defeated(enemies_max-enemies_remaining, enemies_max)
	
	# Conecta o sinal "died" de cada inimigo
	for enemy in enemies:
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
	
	# Se não houver inimigos, já libera a porta
	if enemies_remaining == 0 and door_node:
		door_node.queue_free()
		door_node = null

func _on_enemy_died() -> void:
	enemies_remaining -= 1
	hud_reference._update_enemies_defeated(enemies_max-enemies_remaining, enemies_max)
	if enemies_remaining <= 0:
		if door_node:
			CameraManager.shake(1.8, 3.0)
			AudioManager.tocar_sfxglobal("res://assets/sounds/levels/BossRoomDoor.mp3", {Pitch = 0.5})
			door_node.queue_free()
			door_node = null

# --------------
# EVENTO DE MORTE DO PLAYER
# --------------
func _on_player_died() -> void:
	timer.stop()   # Para o timer quando o player morre
