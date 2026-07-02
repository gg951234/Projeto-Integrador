extends Node

# Dados que não precisam ser salvos
var currentlevel: int = 1
var gamescore: int = 0
var currentlevelroot: Node = null
var currentlevelpath: String = ""

# Dados para serem salvos
var playername: String = ""
var currentscore: int = 0
var currentcoins: int = 0
var unlockedlevels: Array = [1, 2]

# Sistema de transição global
var ui_reference: Control
var transition_layer: CanvasLayer
var transition_rect: ColorRect

func _ready() -> void:
	await get_tree().process_frame
	# ADD FUNÇÃO PARA CARREGAR DADOS DO BANCO DE DADOS
	currentlevelroot = get_tree().root.find_child("LevelRoot", true, false)
	
	# Cria o sistema de transição global (sempre visível, mas transparente)
	_find_nodes()
	_create_transition_system()
	
# --------------
# TRANSIÇÕES DE TELA
# --------------
func _find_nodes() -> void:
	# Procura por um CanvasLayer chamado "FadeTransition" em qualquer lugar da cena root
	var root = get_tree().root
	ui_reference = root.find_child("UI", true, false)
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
	print(levelnumber)
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
	
	if levelnumber in unlockedlevels:
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

func delete_level() -> bool:
	if currentlevelroot:
		currentlevelroot.queue_free()
		currentcoins = 0
		return 1
	return 0

func load_level(levelnumber: int = 0) -> bool:
	if levelnumber <= 0:
		print("Sem levelnumber")
		levelnumber = currentlevel
	
	delete_level()
	
	if check_level(levelnumber):
		currentlevelroot = load(currentlevelpath).instantiate()
		add_child(currentlevelroot)
		currentlevelroot.name = "LevelRoot"
		print("Fase " + str(levelnumber) + " carregada com sucesso")
		
		var player = currentlevelroot.get_node("Player")
		ui_reference.set_player(player)
		
		# Define a câmera do player no CameraManager
		var camera = player.get_node("PlayerCamera")
		
		if camera:
				CameraManager.set_camera(camera)
		else:
				push_warning("Camera2D não encontrada no Player.")
		
		# Define os limites usando o CameraData
		var level_name = "Level" + str(levelnumber)
		CameraManager.set_limits_from_level(level_name, 0.0)  # sem transição no início
		
		# Configura a área de entrada do boss
		setup_boss_enter_area()
		
		currentlevel = levelnumber
		return 1
	else:
		print("Falha ao carregar a fase " + str(levelnumber))
		return 0

func level_completed() -> bool:
	# ENVIAR MOEDAS PARA O BANCO DE DADOS
	unlocknextlevel()
	var death_screen = load("res://scenes/death_screen.tscn").instantiate()
	get_tree().root.add_child(death_screen)
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
		#CameraManager.set_limits_from_level("BossRoom1", 0)
		var bossroom_name = "BossRoom" + str(currentlevel)
		CameraManager.set_camera_to_room(bossroom_name, 0)
		
		# Desconecta o sinal para não disparar novamente
		var enter_area = barrier.get_parent().get_node("Enter")
		if enter_area and enter_area.body_entered.is_connected(_on_boss_enter_area_body_entered):
			enter_area.body_entered.disconnect(_on_boss_enter_area_body_entered)

# --------------
# SISTEMA DE COLETA
# --------------
func unlocknextlevel() -> void:
	if not (currentlevel + 1) in unlockedlevels:
		unlockedlevels.append(currentlevel+1)

func add_coins(amount: int) -> void:
	currentcoins += amount
	print(currentcoins)
